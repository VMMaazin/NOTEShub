import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/acronym_helper.dart';

/// Represents a syllabus subject in the `subjects` Firestore collection.
class SubjectModel {
  final String id;
  final int semester;
  final int subject;
  final String name;

  const SubjectModel({
    required this.id,
    required this.semester,
    required this.subject,
    required this.name,
  });

  /// Subject acronym generated dynamically (e.g. "Web Technology" -> "wt").
  String get acronym => AcronymHelper.generate(name);

  /// Deserializes from Firestore snapshot.
  factory SubjectModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw FormatException('Subject document ${snapshot.id} is empty.');
    }
    return SubjectModel.fromMap(data, snapshot.id);
  }

  /// Deserializes from Map representation.
  factory SubjectModel.fromMap(Map<String, dynamic> data, String id) {
    final semesterRaw = data['semester'];
    final subjectRaw = data['subject'];
    final nameRaw = data['name'];

    if (semesterRaw == null || subjectRaw == null || nameRaw == null) {
      throw FormatException(
        'Invalid Subject document ($id): required fields (semester, subject, name) must not be null.',
      );
    }

    return SubjectModel(
      id: id,
      semester: (semesterRaw as num).toInt(),
      subject: (subjectRaw as num).toInt(),
      name: (nameRaw as String).trim(),
    );
  }

  /// Serializes to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      'semester': semester,
      'subject': subject,
      'name': name,
    };
  }

  SubjectModel copyWith({
    String? id,
    int? semester,
    int? subject,
    String? name,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      semester: semester ?? this.semester,
      subject: subject ?? this.subject,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          semester == other.semester &&
          subject == other.subject &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ semester.hashCode ^ subject.hashCode ^ name.hashCode;

  @override
  String toString() => 'SubjectModel(id: $id, semester: $semester, subject: $subject, name: $name)';
}
