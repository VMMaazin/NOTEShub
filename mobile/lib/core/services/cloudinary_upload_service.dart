import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../utils/file_utils.dart';

/// Result object returned upon a successful Cloudinary upload.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String originalFilename;
  final int bytes;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.originalFilename,
    required this.bytes,
  });
}

/// Service handling direct client-side uploads to Cloudinary RAW storage
/// using the existing unsigned upload preset `college_notes`.
///
/// SECURITY GUARANTEE:
/// - Uses exclusively unsigned uploads.
/// - Never includes or requires the Cloudinary API secret.
/// - Strictly validates PDF magic numbers (%PDF-) before streaming.
class CloudinaryUploadService {
  static const String cloudName = 'debfdnujc';
  static const String uploadPreset = 'college_notes';
  static const String rawUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  // 50 MB maximum document size limit
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  final Dio _dio;

  CloudinaryUploadService({Dio? dio}) : _dio = dio ?? ApiClient.client;

  /// Validates document bytes before initiating network transfer.
  /// Throws [ArgumentError] if the file fails validation.
  static void validatePdfFile({
    required List<int> fileBytes,
    required String fileName,
  }) {
    if (fileBytes.isEmpty) {
      throw ArgumentError('The selected file is empty (0 bytes).');
    }

    if (fileBytes.length > maxFileSizeBytes) {
      final sizeMb = (fileBytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw ArgumentError(
        'File size ($sizeMb MB) exceeds the maximum allowed limit of 50 MB.',
      );
    }

    final lowerName = fileName.toLowerCase();
    if (!lowerName.endsWith('.pdf')) {
      throw ArgumentError(
        'Invalid file type. Only PDF documents (.pdf) are permitted.',
      );
    }

    if (!FileUtils.hasPdfSignature(fileBytes)) {
      throw ArgumentError(
        'Invalid document structure: The file is missing the standard %PDF signature.',
      );
    }
  }

  /// Uploads a PDF document to Cloudinary RAW storage with live progress callbacks.
  Future<CloudinaryUploadResult> uploadPdf({
    required List<int> fileBytes,
    required String fileName,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 1. Client-side sanity validation
    validatePdfFile(fileBytes: fileBytes, fileName: fileName);

    final safeName = FileUtils.sanitizeFileName(fileName);

    // 2. Prepare multipart payload
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: safeName,
      ),
      'upload_preset': uploadPreset,
    });

    try {
      // 3. Post to Cloudinary RAW upload endpoint
      final response = await _dio.post(
        rawUploadUrl,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data;
      if (response.statusCode != 200 || data == null) {
        final errorMsg = (data is Map && data['error'] is Map)
            ? data['error']['message']
            : null;
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: errorMsg ?? 'Cloudinary upload failed with HTTP ${response.statusCode}',
        );
      }

      final secureUrl = data['secure_url'] as String?;
      final publicId = data['public_id'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw StateError('Cloudinary response did not return a secure_url.');
      }

      if (publicId == null || publicId.isEmpty) {
        throw StateError('Cloudinary response did not return a public_id.');
      }

      return CloudinaryUploadResult(
        secureUrl: secureUrl,
        publicId: publicId,
        originalFilename: safeName,
        bytes: fileBytes.length,
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint('Cloudinary upload error: ${e.response?.data ?? e.message}');
      }
      rethrow;
    }
  }
}

