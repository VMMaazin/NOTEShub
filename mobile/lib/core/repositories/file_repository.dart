import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_model.dart';

/// Repository for managing study documents in the `files` Firestore collection.
class FileRepository {
  final FirebaseFirestore? _customFirestore;

  FileRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('files');

  /// Real-time stream of files matching specific academic coordinates.
  /// Matches the query in Next.js FileList.tsx.
  Stream<List<FileModel>> streamFiles({
    required int semester,
    required int subject,
    required int module,
    required String type,
  }) {
    return _collection
        .where('semester', isEqualTo: semester)
        .where('subject', isEqualTo: subject)
        .where('module', isEqualTo: module)
        .where('type', isEqualTo: type.toLowerCase())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FileModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Real-time stream of all files for a specific semester, subject, and module
  /// across all categories (Notes, Question Bank, Extra Resources).
  Stream<List<FileModel>> streamModuleFiles({
    required int semester,
    required int subject,
    required int module,
  }) {
    return _collection
        .where('semester', isEqualTo: semester)
        .where('subject', isEqualTo: subject)
        .where('module', isEqualTo: module)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FileModel.fromFirestore(doc))
          .toList();
    });
  }

  /// One-time fetch of files for a specific module & category.
  Future<List<FileModel>> getFiles({
    required int semester,
    required int subject,
    required int module,
    required String type,
  }) async {
    final querySnap = await _collection
        .where('semester', isEqualTo: semester)
        .where('subject', isEqualTo: subject)
        .where('module', isEqualTo: module)
        .where('type', isEqualTo: type.toLowerCase())
        .get();

    return querySnap.docs
        .map((doc) => FileModel.fromFirestore(doc))
        .toList();
  }

  /// Fetches an individual file document by its [fileId].
  Future<FileModel?> getFile(String fileId) async {
    final docSnap = await _collection.doc(fileId).get();
    if (!docSnap.exists || docSnap.data() == null) return null;
    return FileModel.fromFirestore(docSnap);
  }

  /// Bulk fetch of all files in the collection (used by Search in Phase 3).
  Future<List<FileModel>> getAllFiles() async {
    final querySnap = await _collection.get();
    return querySnap.docs
        .map((doc) => FileModel.fromFirestore(doc))
        .toList();
  }

  /// Renames an existing file document in Firestore.
  Future<void> updateFileName({
    required String docId,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('File name cannot be empty.');
    }
    await _collection.doc(docId).update({'name': trimmed});
  }

  /// Deletes a file document from Firestore.
  Future<void> deleteFileDoc(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// Checks whether an identical file record already exists at these academic coordinates.
  Future<bool> fileRecordExists({
    required int semester,
    required int subject,
    required int module,
    required String type,
    required String name,
  }) async {
    final snap = await _collection
        .where('semester', isEqualTo: semester)
        .where('subject', isEqualTo: subject)
        .where('module', isEqualTo: module)
        .where('type', isEqualTo: type.toLowerCase())
        .where('name', isEqualTo: name.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Records newly uploaded file metadata to Firestore.
  /// Prevents accidental duplicate entries if [preventDuplicates] is true.
  Future<String> addFileRecord({
    required int semester,
    required int subject,
    required int module,
    required String type,
    required String name,
    required String url,
    required String publicId,
    bool preventDuplicates = true,
  }) async {
    final trimmedName = name.trim();
    if (preventDuplicates) {
      final exists = await fileRecordExists(
        semester: semester,
        subject: subject,
        module: module,
        type: type,
        name: trimmedName,
      );
      if (exists) {
        throw StateError(
          'A document named "$trimmedName" already exists in Semester $semester, Subject $subject, Module $module.',
        );
      }
    }

    final docRef = await _collection.add({
      'semester': semester,
      'subject': subject,
      'module': module,
      'type': type.toLowerCase(),
      'name': trimmedName,
      'url': url.trim(),
      'publicId': publicId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }
}

