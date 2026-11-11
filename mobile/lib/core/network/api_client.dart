import 'package:dio/dio.dart';

/// Centralized networking client for Cloudinary and future cloud functions.
class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get client => _dio;

  /// Returns direct attachment URL matching Next.js fl_attachment transformation.
  static String getAttachmentUrl(String rawUrl) {
    if (rawUrl.contains('/upload/fl_attachment/')) {
      return rawUrl;
    }
    if (rawUrl.contains('/upload/')) {
      return rawUrl.replaceFirst('/upload/', '/upload/fl_attachment/');
    }
    return rawUrl;
  }

  /// Returns a clean streaming URL without attachment disposition for in-app PDF rendering.
  static String getRawStreamingUrl(String url) {
    if (url.contains('/upload/fl_attachment/')) {
      return url.replaceFirst('/upload/fl_attachment/', '/upload/');
    }
    return url;
  }
}
