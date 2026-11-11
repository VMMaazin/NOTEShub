import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

/// Repository for managing subjects in the `subjects` Firestore collection.
class SubjectRepository {
  final FirebaseFirestore? _customFirestore;

  SubjectRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('subjects');

  /// Retrieves all subjects configured for a given [semester] (e.g. 4 or 5).
  Future<List<SubjectModel>> getSubjects(int semester) async {
    final querySnap = await _collection
        .where('semester', isEqualTo: semester)
        .get();

    return querySnap.docs
        .map((doc) => SubjectModel.fromFirestore(doc))
        .toList();
  }

  /// Retrieves all subjects across all semesters (used for caching & search).
  Future<List<SubjectModel>> getAllSubjects() async {
    final querySnap = await _collection.get();
    return querySnap.docs
        .map((doc) => SubjectModel.fromFirestore(doc))
        .toList();
  }

  /// Retrieves list of unique semester numbers that have subjects defined in Firestore.
  /// Falls back to active semesters [4, 5] if offline or initial setup.
  Future<List<int>> getAvailableSemesters() async {
    try {
      final querySnap = await _collection.get();
      final semesters = querySnap.docs
          .map((doc) => doc.data()['semester'])
          .whereType<num>()
          .map((sem) => sem.toInt())
          .toSet()
          .toList();
      semesters.sort();
      return semesters.isNotEmpty ? semesters : [4, 5];
    } catch (_) {
      return [4, 5];
    }
  }

  /// Real-time stream of subjects for a given [semester].
  Stream<List<SubjectModel>> streamSubjects(int semester) {
    return _collection
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SubjectModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Retrieves an individual subject by its [semester] and [subjectId] slot (1 through 8).
  Future<SubjectModel?> getSubject({
    required int semester,
    required int subjectId,
  }) async {
    final querySnap = await _collection
        .where('semester', isEqualTo: semester)
        .where('subject', isEqualTo: subjectId)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) return null;
    return SubjectModel.fromFirestore(querySnap.docs.first);
  }

  /// Updates a subject name, or creates the document if it does not yet exist.
  /// Fixes the Next.js Semester 4 bug where missing documents could not be saved.
  Future<String> saveSubjectName({
    required int semester,
    required int subjectId,
    required String newName,
    String? existingDocId,
  }) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Subject name cannot be empty.');
    }

    if (existingDocId != null && existingDocId.isNotEmpty) {
      await _collection.doc(existingDocId).update({'name': trimmedName});
      return existingDocId;
    }

    // Check if document exists by query before creating
    final existing = await getSubject(semester: semester, subjectId: subjectId);
    if (existing != null) {
      await _collection.doc(existing.id).update({'name': trimmedName});
      return existing.id;
    }

    // Create new subject document using deterministic "${semester}_${subject}" ID
    final docId = '${semester}_$subjectId';
    await _collection.doc(docId).set({
      'semester': semester,
      'subject': subjectId,
      'name': trimmedName,
    });
    return docId;
  }

  /// Adds a new subject to a semester.
  /// Enforces semester (1-8), subject slot (1-8), non-empty name,
  /// and prevents duplicate slot entries.
  Future<String> addSubject({
    required int semester,
    required int subjectId,
    required String name,
  }) async {
    if (semester < 1 || semester > 8) {
      throw ArgumentError('Semester must be between 1 and 8.');
    }
    if (subjectId < 1 || subjectId > 8) {
      throw ArgumentError('Subject slot must be between 1 and 8.');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Subject name cannot be empty.');
    }

    // Check if slot already exists in this semester
    final existing = await getSubject(semester: semester, subjectId: subjectId);
    if (existing != null) {
      throw StateError(
        'Subject slot $subjectId in Semester $semester is already occupied by "${existing.name}".',
      );
    }

    final docId = '${semester}_$subjectId';
    await _collection.doc(docId).set({
      'semester': semester,
      'subject': subjectId,
      'name': trimmedName,
    });
    return docId;
  }
}

