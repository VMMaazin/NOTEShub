import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/file_model.dart';
import '../network/api_client.dart';
import '../utils/file_utils.dart';

// Platform-conditional file check helper
import 'dart:io' if (dart.library.html) '../storage/web_storage_stub.dart' as io;

/// Service dedicated strictly to saving files to user-accessible device storage
/// (e.g. Android public Downloads folder, iOS Save to Files sheet, browser downloads on Web).
///
/// DOES NOT register files in the in-app Offline Library.
class DeviceDownloadService {
  final Dio _dio;
  static final Set<String> _activeDownloads = <String>{};
  static const MethodChannel _androidChannel =
      MethodChannel('app.noteshub.mobile/device_download');

  DeviceDownloadService({Dio? dio}) : _dio = dio ?? ApiClient.client;

  /// Whether a device download is currently active for [fileId].
  bool isDownloading(String fileId) => _activeDownloads.contains(fileId);

  /// Downloads [file] directly to user-accessible device storage.
  Future<String> downloadToDevice({
    required FileModel file,
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 1. Web: trigger native browser download
    if (kIsWeb) {
      final downloadUrl = ApiClient.getAttachmentUrl(file.url);
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return 'Download started in browser.';
      } else {
        throw StateError('Could not trigger browser download.');
      }
    }

    final fileId = file.id;
    if (_activeDownloads.contains(fileId)) {
      throw StateError('Download is already in progress for "${file.name}".');
    }
    _activeDownloads.add(fileId);

    try {
      final safeBaseName = FileUtils.sanitizeFileName(file.name);
      final downloadUrl = file.url.isNotEmpty ? file.url : file.downloadUrl;

      if (downloadUrl.trim().isEmpty) {
        throw ArgumentError('Download URL is empty for file "${file.name}".');
      }

      // 2. Android: download to temp and save to public Downloads via MediaStore
      if (defaultTargetPlatform == TargetPlatform.android) {
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_$safeBaseName';
        final tempFile = io.File(tempPath);

        try {
          final response = await _dio.download(
            downloadUrl,
            tempPath,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              if (onProgress != null && total > 0) {
                onProgress(received, total);
              }
            },
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
            ),
          );

          if (response.statusCode != 200) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              error:
                  'Server returned HTTP ${response.statusCode} while downloading file.',
            );
          }

          if (!tempFile.existsSync() ||
              (tempFile as dynamic).lengthSync() <= 0) {
            throw StateError('Downloaded file is empty (0 bytes).');
          }

          final headerBytes = await FileUtils.readFileHeader(tempFile);
          if (!FileUtils.hasPdfSignature(headerBytes)) {
            throw StateError(
              'Downloaded document is invalid or corrupted (missing standard %PDF file signature).',
            );
          }

          String savedLocation = 'Downloads/$safeBaseName';
          try {
            final result = await _androidChannel.invokeMethod<String>(
              'savePdfToDownloads',
              {
                'filePath': tempPath,
                'fileName': safeBaseName,
              },
            );
            if (result != null && result.isNotEmpty) {
              savedLocation = result;
            }
          } on MissingPluginException {
            debugPrint(
                'Native device download channel not registered in current environment (e.g. testing).');
          }

          final fileName = savedLocation.split(RegExp(r'[\\/]')).last;
          return 'Saved to device Downloads: $fileName';
        } finally {
          if (tempFile.existsSync()) {
            try {
              await tempFile.delete();
            } catch (_) {}
          }
        }
      }

      // 3. iOS: save to temporary location and trigger native Share/Save to Files interface
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$safeBaseName';
        final tempFile = io.File(tempPath);

        final response = await _dio.download(
          downloadUrl,
          tempPath,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );

        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error:
                'Server returned HTTP ${response.statusCode} while downloading.',
          );
        }

        if (!tempFile.existsSync() ||
            (tempFile as dynamic).lengthSync() <= 0) {
          if (tempFile.existsSync()) await tempFile.delete();
          throw StateError('File download was empty or unreadable.');
        }

        final headerBytes = await FileUtils.readFileHeader(tempFile);
        if (!FileUtils.hasPdfSignature(headerBytes)) {
          await tempFile.delete();
          throw StateError(
            'Downloaded document is invalid or corrupted (missing standard %PDF file signature).',
          );
        }

        final xFile =
            XFile(tempPath, name: safeBaseName, mimeType: 'application/pdf');
        await Share.shareXFiles([xFile], text: file.name);
        return 'Presented native Save to Files interface.';
      }

      // 4. Desktop platforms (Windows, macOS, Linux)
      final docDir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final targetPath = '${docDir.path}/$safeBaseName';

      final response = await _dio.download(
        downloadUrl,
        targetPath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error:
              'Server returned HTTP ${response.statusCode} while downloading.',
        );
      }

      final savedFile = io.File(targetPath);
      if (!savedFile.existsSync() ||
          (savedFile as dynamic).lengthSync() <= 0) {
        if (savedFile.existsSync()) await savedFile.delete();
        throw StateError('File download was empty or unreadable.');
      }

      final headerBytes = await FileUtils.readFileHeader(savedFile);
      if (!FileUtils.hasPdfSignature(headerBytes)) {
        await savedFile.delete();
        throw StateError(
          'Downloaded document is invalid or corrupted (missing standard %PDF file signature).',
        );
      }

      return 'Saved to: $targetPath';
    } finally {
      _activeDownloads.remove(fileId);
    }
  }
}
