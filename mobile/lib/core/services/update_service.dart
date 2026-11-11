import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/update_info_model.dart';
import '../network/api_client.dart';

/// Result object emitted when checking for application updates.
class UpdateCheckResult {
  final UpdateInfoModel updateInfo;
  final String currentVersion;
  final int currentVersionCode;
  final bool isUpdateAvailable;
  final bool fromCache;

  const UpdateCheckResult({
    required this.updateInfo,
    required this.currentVersion,
    required this.currentVersionCode,
    required this.isUpdateAvailable,
    this.fromCache = false,
  });
}

/// Installation initiation status.
enum InstallLaunchStatus {
  launched,
  permissionRequired,
  fileNotFound,
  failed,
}

class AppInstallResult {
  final InstallLaunchStatus status;
  final String message;
  final String? filePath;

  const AppInstallResult({
    required this.status,
    required this.message,
    this.filePath,
  });
}

/// Robust background service managing automatic in-app updates for NOTEShub.
///
/// Features:
/// - Single check on app launch running non-blockingly.
/// - Android-only execution guard.
/// - 5-second short timeout with resilient error handling.
/// - 6-hour caching with SharedPreferences.
/// - Session deduplication to avoid repetitive prompts.
/// - APK integrity & ZIP header validation.
/// - Android package installer invocation.
class UpdateService {
  final Dio _dio;
  final String _metadataUrl;
  SharedPreferences? _prefs;
  PackageInfo? _packageInfo;

  /// In-memory tracker preventing repetitive prompts during a single app session.
  static bool _hasPromptedThisSession = false;

  UpdateService({
    Dio? dio,
    String? metadataUrl,
    SharedPreferences? prefs,
    PackageInfo? packageInfo,
  })  : _dio = dio ?? ApiClient.client,
        _metadataUrl = metadataUrl ?? AppConstants.updateMetadataUrl,
        _prefs = prefs,
        _packageInfo = packageInfo;

  /// Resets session prompt tracker (primarily for testing purposes).
  @visibleForTesting
  static void resetSessionPrompt() {
    _hasPromptedThisSession = false;
  }

  /// Whether the user was already prompted during this session.
  static bool get hasPromptedThisSession => _hasPromptedThisSession;

  /// Marks that an update prompt was displayed in this session.
  static void markPromptedThisSession() {
    _hasPromptedThisSession = true;
  }

  /// Initializes local preferences and package info if not already injected.
  Future<void> _ensureInitialized() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('UpdateService: SharedPreferences warning: $e');
    }

    try {
      _packageInfo ??= await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('UpdateService: PackageInfo warning: $e');
    }
  }

  /// Retrieves current installed version code.
  Future<int> getCurrentVersionCode() async {
    await _ensureInitialized();
    final rawBuildNumber = _packageInfo?.buildNumber;
    if (rawBuildNumber != null && rawBuildNumber.isNotEmpty) {
      final parsed = int.tryParse(rawBuildNumber);
      if (parsed != null && parsed > 0) return parsed;
    }
    return AppConstants.appVersionCode;
  }

  /// Retrieves current installed version name.
  Future<String> getCurrentVersionName() async {
    await _ensureInitialized();
    final rawVersion = _packageInfo?.version;
    if (rawVersion != null && rawVersion.isNotEmpty) {
      return rawVersion;
    }
    return AppConstants.appVersion;
  }

  /// Checks for available updates asynchronously.
  ///
  /// Returns `null` if platform is not Android, if network fails, or if cached.
  Future<UpdateCheckResult?> checkForUpdate({
    bool forceCheck = false,
  }) async {
    // 1. Platform Guard: Android only for APK distribution
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    await _ensureInitialized();
    final currentCode = await getCurrentVersionCode();
    final currentName = await getCurrentVersionName();

    // 2. Cache Check: 6-hour throttle (unless forceCheck is true)
    if (!forceCheck && _prefs != null) {
      final lastCheckMs = _prefs!.getInt(AppConstants.updateLastCheckedPrefKey) ?? 0;
      final cachedJsonStr = _prefs!.getString(AppConstants.updateCachedMetadataPrefKey);
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheckMs;

      if (elapsed < AppConstants.updateCacheDuration.inMilliseconds && cachedJsonStr != null) {
        try {
          final decoded = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
          final cachedModel = UpdateInfoModel.fromJson(decoded);
          final isAvail = cachedModel.isUpdateAvailable(currentVersionCode: currentCode);
          return UpdateCheckResult(
            updateInfo: cachedModel,
            currentVersion: currentName,
            currentVersionCode: currentCode,
            isUpdateAvailable: isAvail,
            fromCache: true,
          );
        } catch (_) {
          // If cached data was corrupted, proceed to fresh fetch
        }
      }
    }

    // 3. Network Fetch with 5s Timeout
    try {
      final response = await _dio.get<dynamic>(
        _metadataUrl,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: AppConstants.updateCheckTimeout,
          receiveTimeout: AppConstants.updateCheckTimeout,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final dynamic rawData = response.data;
      Map<String, dynamic> jsonMap;
      if (rawData is Map<String, dynamic>) {
        jsonMap = rawData;
      } else if (rawData is String) {
        final decoded = jsonDecode(rawData);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        jsonMap = decoded;
      } else {
        return null;
      }

      final updateModel = UpdateInfoModel.fromJson(jsonMap);
      final isAvailable = updateModel.isUpdateAvailable(currentVersionCode: currentCode);

      // Cache successful response
      if (_prefs != null) {
        await _prefs!.setInt(
          AppConstants.updateLastCheckedPrefKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        await _prefs!.setString(
          AppConstants.updateCachedMetadataPrefKey,
          jsonEncode(updateModel.toJson()),
        );
      }

      return UpdateCheckResult(
        updateInfo: updateModel,
        currentVersion: currentName,
        currentVersionCode: currentCode,
        isUpdateAvailable: isAvailable,
        fromCache: false,
      );
    } catch (e) {
      // Graceful failure: timeout, socket error, offline, or invalid schema
      debugPrint('UpdateService check error (gracefully suppressed): $e');
      return null;
    }
  }

  /// Validates that the downloaded file at [path] is an authentic APK file
  /// and not an HTML error response or corrupted payload.
  static Future<bool> validateApkFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final length = await file.length();
      // Valid NOTEShub APK is at least several megabytes
      if (length < 100 * 1024) return false;

      // Inspect ZIP/APK magic signature bytes: 0x50, 0x4B, 0x03, 0x04 ("PK\x03\x04")
      final raf = await file.open(mode: FileMode.read);
      final header = await raf.read(4);
      await raf.close();

      if (header.length < 4) return false;
      return header[0] == 0x50 &&
          header[1] == 0x4B &&
          header[2] == 0x03 &&
          header[3] == 0x04;
    } catch (e) {
      debugPrint('UpdateService APK validation warning: $e');
      return false;
    }
  }

  /// Downloads the release APK with progress tracking, validates integrity,
  /// and hands over installation to the Android OS Package Installer.
  Future<AppInstallResult> downloadAndInstall({
    required UpdateInfoModel update,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const AppInstallResult(
        status: InstallLaunchStatus.failed,
        message: 'In-app APK installation is supported on Android devices only.',
      );
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final updatesDir = Directory('${tempDir.path}/updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      final targetPath = '${updatesDir.path}/NOTEShub-v${update.version}.apk';
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // 1. Download APK from HTTPS URL
      final response = await _dio.download(
        update.apkUrl,
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
        return AppInstallResult(
          status: InstallLaunchStatus.failed,
          message: 'Download server responded with HTTP ${response.statusCode}.',
        );
      }

      // 2. Validate APK integrity
      final isValid = await validateApkFile(targetPath);
      if (!isValid) {
        if (await targetFile.exists()) await targetFile.delete();
        return const AppInstallResult(
          status: InstallLaunchStatus.failed,
          message: 'Downloaded package is invalid or corrupted. Please verify your connection.',
        );
      }

      // 3. Launch Android Package Installer
      final openResult = await OpenFilex.open(
        targetPath,
        type: 'application/vnd.android.package-archive',
      );

      switch (openResult.type) {
        case ResultType.done:
          return AppInstallResult(
            status: InstallLaunchStatus.launched,
            message: 'Installation started.',
            filePath: targetPath,
          );
        case ResultType.permissionDenied:
          return AppInstallResult(
            status: InstallLaunchStatus.permissionRequired,
            message: 'Please enable "Install unknown apps" permission for NOTEShub in Android Settings.',
            filePath: targetPath,
          );
        case ResultType.fileNotFound:
          return const AppInstallResult(
            status: InstallLaunchStatus.fileNotFound,
            message: 'Downloaded APK file was not found.',
          );
        case ResultType.noAppToOpen:
        case ResultType.error:
          return AppInstallResult(
            status: InstallLaunchStatus.failed,
            message: openResult.message.isNotEmpty
                ? openResult.message
                : 'Unable to initiate Android package installer.',
            filePath: targetPath,
          );
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return const AppInstallResult(
          status: InstallLaunchStatus.failed,
          message: 'Download cancelled.',
        );
      }
      return AppInstallResult(
        status: InstallLaunchStatus.failed,
        message: 'Download error: $e',
      );
    }
  }
}

