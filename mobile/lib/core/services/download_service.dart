import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file_model.dart';
import '../models/offline_document_model.dart';
import '../network/api_client.dart';
import '../utils/file_utils.dart';

// Platform-conditional file deletion/check helper
import 'dart:io' if (dart.library.html) '../storage/web_storage_stub.dart' as io;

/// Service handling cross-platform PDF file downloading with progress tracking,
/// validation, duplicate prevention, and platform-aware storage paths.
class DownloadService {
  final Dio _dio;
  final Set<String> _activeDownloads = <String>{};
  final Map<String, CancelToken> _cancelTokens = <String, CancelToken>{};

  DownloadService({Dio? dio}) : _dio = dio ?? ApiClient.client;

  /// Whether a download is currently active for the given [fileId].
  bool isDownloading(String fileId) => _activeDownloads.contains(fileId);

  /// Cancels an in-progress download if active.
  void cancelDownload(String fileId) {
    if (_cancelTokens.containsKey(fileId)) {
      _cancelTokens[fileId]?.cancel('Download cancelled by user.');
      _cancelTokens.remove(fileId);
      _activeDownloads.remove(fileId);
    }
  }

  /// Downloads a document and saves it locally.
  ///
  /// On Android & iOS: Saves to `<AppDocuments>/noteshub_downloads/<safe_name>.pdf`.
  /// On Web: Triggers browser download via Cloudinary attachment URL.
  Future<OfflineDocumentModel> downloadFile({
    required FileModel file,
    Function(int received, int total)? onProgress,
  }) async {
    final fileId = file.id;

    // 1. Prevent concurrent duplicate downloads of the same file
    if (_activeDownloads.contains(fileId)) {
      throw StateError('Download is already in progress for "${file.name}".');
    }

    _activeDownloads.add(fileId);
    final cancelToken = CancelToken();
    _cancelTokens[fileId] = cancelToken;

    try {
      // 2. Web platform handling: Do NOT falsely report as an offline document
      if (kIsWeb) {
        throw UnsupportedError(
          'In-app offline private storage is supported on Android & iOS mobile devices. On Web, please choose "Download to Device".',
        );
      }

      // 3. Native platform handling (Android & iOS)
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadsDir = io.Directory('${appDocDir.path}/noteshub_downloads');
      if (!downloadsDir.existsSync()) {
        await downloadsDir.create(recursive: true);
      }

      // Safe, collision-resistant filename
      final safeBaseName = FileUtils.sanitizeFileName(file.name);
      final finalPath = '${downloadsDir.path}/${file.id}_$safeBaseName';

      // Prefer original Cloudinary RAW URL to avoid redirect loops on Dio streaming
      final downloadUrl = file.url.isNotEmpty ? file.url : file.downloadUrl;

      final response = await _dio.download(
        downloadUrl,
        finalPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
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
          error: 'Server returned HTTP ${response.statusCode} while downloading file.',
        );
      }

      // 4. Validate saved file
      final savedFile = io.File(finalPath);
      if (!savedFile.existsSync()) {
        throw StateError('File download completed but target file was not found on disk.');
      }

      // Read file size
      final fileSize = (savedFile as dynamic).lengthSync() as int;
      if (fileSize <= 0) {
        await savedFile.delete();
        throw StateError('Downloaded file is empty (0 bytes).');
      }

      // 5. Validate PDF magic bytes header (%PDF)
      final headerBytes = await FileUtils.readFileHeader(savedFile);
      if (!FileUtils.hasPdfSignature(headerBytes)) {
        await savedFile.delete();
        throw StateError(
          'Downloaded document is invalid or corrupted (missing standard %PDF file signature).',
        );
      }

      return OfflineDocumentModel.fromFileModel(
        file: file,
        localPath: finalPath,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now(),
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('Download cancelled: ${file.name}');
      }
      rethrow;
    } finally {
      _activeDownloads.remove(fileId);
      _cancelTokens.remove(fileId);
    }
  }
}

