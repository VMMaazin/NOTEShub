import 'package:cloud_firestore/cloud_firestore.dart';
import '../network/api_client.dart';

/// Supported study material file categories.
class FileCategory {
  static const String notes = 'notes';
  static const String qbank = 'qbank';
  static const String extra = 'extra';

  static const List<String> all = [notes, qbank, extra];

  static bool isValid(String type) => all.contains(type.toLowerCase());
}

/// Represents an uploaded study material document in the `files` Firestore collection.
class FileModel {
  final String id;
  final int semester;
  final int subject;
  final int module;
  final String type; // 'notes' | 'qbank' | 'extra'
  final String name;
  final String url;
  final String publicId;
  final Timestamp? createdAt;

  const FileModel({
    required this.id,
    required this.semester,
    required this.subject,
    required this.module,
    required this.type,
    required this.name,
    required this.url,
    required this.publicId,
    this.createdAt,
  });

  /// Cloudinary URL transformed with `fl_attachment` for native device downloads.
  String get downloadUrl => ApiClient.getAttachmentUrl(url);

  /// Whether the file is a PDF document.
  bool get isPdf =>
      url.toLowerCase().contains('.pdf') || name.toLowerCase().endsWith('.pdf');

  /// Deserializes from Firestore snapshot.
  factory FileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException('File document ${snapshot.id} is empty.');
    }
    return FileModel.fromMap(data, snapshot.id);
  }

  /// Deserializes from Map representation with strict validation for required fields.
  factory FileModel.fromMap(Map<String, dynamic> data, String id) {
    final semesterRaw = data['semester'];
    final subjectRaw = data['subject'];
    final moduleRaw = data['module'];
    final typeRaw = data['type'];
    final nameRaw = data['name'];
    final urlRaw = data['url'];
    final publicIdRaw = data['publicId'];

    if (semesterRaw == null ||
        subjectRaw == null ||
        moduleRaw == null ||
        typeRaw == null ||
        nameRaw == null ||
        urlRaw == null ||
        publicIdRaw == null) {
      throw FormatException(
        'Invalid File document ($id): required fields (semester, subject, module, type, name, url, publicId) must not be null.',
      );
    }

    final typeStr = (typeRaw as String).trim().toLowerCase();

    // Safely parse optional Timestamp
    Timestamp? parsedTimestamp;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedTimestamp = rawCreatedAt;
    } else if (rawCreatedAt is DateTime) {
      parsedTimestamp = Timestamp.fromDate(rawCreatedAt);
    }

    return FileModel(
      id: id,
      semester: (semesterRaw as num).toInt(),
      subject: (subjectRaw as num).toInt(),
      module: (moduleRaw as num).toInt(),
      type: typeStr,
      name: (nameRaw as String).trim(),
      url: (urlRaw as String).trim(),
      publicId: (publicIdRaw as String).trim(),
      createdAt: parsedTimestamp,
    );
  }

  /// Serializes to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'semester': semester,
      'subject': subject,
      'module': module,
      'type': type,
      'name': name,
      'url': url,
      'publicId': publicId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  FileModel copyWith({
    String? id,
    int? semester,
    int? subject,
    int? module,
    String? type,
    String? name,
    String? url,
    String? publicId,
    Timestamp? createdAt,
  }) {
    return FileModel(
      id: id ?? this.id,
      semester: semester ?? this.semester,
      subject: subject ?? this.subject,
      module: module ?? this.module,
      type: type ?? this.type,
      name: name ?? this.name,
      url: url ?? this.url,
      publicId: publicId ?? this.publicId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          url == other.url &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ url.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'FileModel(id: $id, name: $name, semester: $semester, subject: $subject, module: $module, type: $type)';
}

