import 'dart:convert';
import 'file_model.dart';

/// Represents a document stored locally on device for offline studying.
class OfflineDocumentModel {
  final String id;
  final String name;
  final int semester;
  final int subject;
  final int module;
  final String type;
  final String url;
  final String publicId;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;

  const OfflineDocumentModel({
    required this.id,
    required this.name,
    required this.semester,
    required this.subject,
    required this.module,
    required this.type,
    required this.url,
    required this.publicId,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  /// Factory from a [FileModel] and local file metadata.
  factory OfflineDocumentModel.fromFileModel({
    required FileModel file,
    required String localPath,
    required int fileSizeBytes,
    DateTime? downloadedAt,
  }) {
    return OfflineDocumentModel(
      id: file.id,
      name: file.name,
      semester: file.semester,
      subject: file.subject,
      module: file.module,
      type: file.type,
      url: file.url,
      publicId: file.publicId,
      localPath: localPath,
      fileSizeBytes: fileSizeBytes,
      downloadedAt: downloadedAt ?? DateTime.now(),
    );
  }

  /// Converts this offline document back to a [FileModel] for preview dialogs.
  FileModel toFileModel() {
    return FileModel(
      id: id,
      semester: semester,
      subject: subject,
      module: module,
      type: type,
      name: name,
      url: url,
      publicId: publicId,
    );
  }

  /// Formatted file size string (e.g. "2.4 MB" or "840 KB").
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'semester': semester,
      'subject': subject,
      'module': module,
      'type': type,
      'url': url,
      'publicId': publicId,
      'localPath': localPath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory OfflineDocumentModel.fromMap(Map<String, dynamic> map) {
    return OfflineDocumentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      semester: (map['semester'] as num).toInt(),
      subject: (map['subject'] as num).toInt(),
      module: (map['module'] as num).toInt(),
      type: map['type'] as String,
      url: map['url'] as String,
      publicId: map['publicId'] as String,
      localPath: map['localPath'] as String,
      fileSizeBytes: (map['fileSizeBytes'] as num).toInt(),
      downloadedAt: DateTime.parse(map['downloadedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory OfflineDocumentModel.fromJson(String source) =>
      OfflineDocumentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineDocumentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

