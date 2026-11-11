import 'package:flutter/foundation.dart';

/// Represents parsed metadata regarding an available application update.
@immutable
class UpdateInfoModel {
  final String version;
  final int versionCode;
  final String apkUrl;
  final bool forceUpdate;
  final String releaseNotes;
  final int? minSupportedVersionCode;

  const UpdateInfoModel({
    required this.version,
    required this.versionCode,
    required this.apkUrl,
    this.forceUpdate = false,
    this.releaseNotes = '',
    this.minSupportedVersionCode,
  });

  /// Factory deserializer validating JSON schema and enforcing HTTPS security.
  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    if (rawVersion == null || rawVersion.toString().trim().isEmpty) {
      throw const FormatException('Missing or invalid "version" in update metadata.');
    }

    final rawCode = json['versionCode'];
    int? parsedCode;
    if (rawCode is int) {
      parsedCode = rawCode;
    } else if (rawCode is String) {
      parsedCode = int.tryParse(rawCode.trim());
    }
    if (parsedCode == null || parsedCode <= 0) {
      throw FormatException('Invalid "versionCode": $rawCode. Must be a positive integer.');
    }

    final rawUrl = json['apkUrl'];
    if (rawUrl == null || rawUrl.toString().trim().isEmpty) {
      throw const FormatException('Missing "apkUrl" in update metadata.');
    }
    final apkUrlStr = rawUrl.toString().trim();
    final uri = Uri.tryParse(apkUrlStr);
    if (uri == null || !uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
      throw FormatException('Insecure or invalid "apkUrl": $apkUrlStr. Only HTTPS URLs are permitted.');
    }

    final rawForce = json['forceUpdate'];
    final forceUpdate = rawForce is bool
        ? rawForce
        : (rawForce?.toString().toLowerCase() == 'true');

    final releaseNotes = (json['releaseNotes']?.toString() ?? '').trim();

    int? minCode;
    final rawMin = json['minSupportedVersionCode'];
    if (rawMin is int) {
      minCode = rawMin;
    } else if (rawMin is String) {
      minCode = int.tryParse(rawMin.trim());
    }

    return UpdateInfoModel(
      version: rawVersion.toString().trim(),
      versionCode: parsedCode,
      apkUrl: apkUrlStr,
      forceUpdate: forceUpdate,
      releaseNotes: releaseNotes.isNotEmpty ? releaseNotes : 'General performance improvements and bug fixes.',
      minSupportedVersionCode: minCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'versionCode': versionCode,
        'apkUrl': apkUrl,
        'forceUpdate': forceUpdate,
        'releaseNotes': releaseNotes,
        if (minSupportedVersionCode != null)
          'minSupportedVersionCode': minSupportedVersionCode,
      };

  /// Evaluates whether this metadata denotes a strictly newer version
  /// relative to the current installed versionCode.
  bool isUpdateAvailable({
    required int currentVersionCode,
    String? currentVersionName,
  }) {
    if (versionCode > currentVersionCode) {
      return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateInfoModel &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          versionCode == other.versionCode &&
          apkUrl == other.apkUrl &&
          forceUpdate == other.forceUpdate;

  @override
  int get hashCode => Object.hash(version, versionCode, apkUrl, forceUpdate);

  @override
  String toString() =>
      'UpdateInfoModel(v$version+$versionCode, force: $forceUpdate, url: $apkUrl)';
}

