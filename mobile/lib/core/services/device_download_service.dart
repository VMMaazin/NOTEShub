import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  DeviceDownloadService({Dio? dio}) : _dio = dio ?? ApiClient.client;

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

    final safeBaseName = FileUtils.sanitizeFileName(file.name);
    final downloadUrl = file.url.isNotEmpty ? file.url : file.downloadUrl;

    // 2. Android: save to public Downloads folder
    if (defaultTargetPlatform == TargetPlatform.android) {
      String? targetDirPath;
      try {
        final downloads = await getDownloadsDirectory();
        targetDirPath = downloads?.path;
      } catch (_) {}

      // Fallback to standard external storage Download path
      targetDirPath ??= '/storage/emulated/0/Download';
      final dirObj = io.Directory(targetDirPath);
      if (!dirObj.existsSync()) {
        try {
          await dirObj.create(recursive: true);
        } catch (_) {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            targetDirPath = ext.path;
          }
        }
      }

      String targetPath = '$targetDirPath/$safeBaseName';
      // Ensure unique filename if file already exists
      int counter = 1;
      final dotIndex = safeBaseName.lastIndexOf('.');
      final nameWithoutExt = dotIndex != -1 ? safeBaseName.substring(0, dotIndex) : safeBaseName;
      final ext = dotIndex != -1 ? safeBaseName.substring(dotIndex) : '.pdf';

      while (io.File(targetPath).existsSync()) {
        targetPath = '$targetDirPath/$nameWithoutExt ($counter)$ext';
        counter++;
      }

      final response = await _dio.download(
        downloadUrl,
        targetPath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Server returned HTTP ${response.statusCode} while downloading.',
        );
      }

      final savedFile = io.File(targetPath);
      if (!savedFile.existsSync() || (savedFile as dynamic).lengthSync() <= 0) {
        if (savedFile.existsSync()) await savedFile.delete();
        throw StateError('File download was empty or unreadable.');
      }

      final fileName = targetPath.split(RegExp(r'[\\/]')).last;
      return 'Saved to device Downloads: $fileName';
    }

    // 3. iOS: save to temporary location and trigger native Share/Save to Files interface
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$safeBaseName';

      final response = await _dio.download(
        downloadUrl,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Server returned HTTP ${response.statusCode} while downloading.',
        );
      }

      final savedFile = io.File(tempPath);
      if (!savedFile.existsSync()) {
        throw StateError('Failed to prepare document for device saving.');
      }

      final xFile = XFile(tempPath, name: safeBaseName, mimeType: 'application/pdf');
      await Share.shareXFiles([xFile], text: file.name);
      return 'Presented native Save to Files interface.';
    }

    // 4. Desktop platforms (Windows, macOS, Linux)
    final docDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final targetPath = '${docDir.path}/$safeBaseName';

    await _dio.download(
      downloadUrl,
      targetPath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
    );

    return 'Saved to: $targetPath';
  }
}

