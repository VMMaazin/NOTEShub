import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/offline_document_model.dart';
import '../storage/local_storage_service.dart';

// Platform-conditional file deletion helper
import 'dart:io' if (dart.library.html) '../storage/web_storage_stub.dart' as io;

/// Service managing the local offline document registry and local file lifecycles.
/// Guarantees that local deletion NEVER impacts remote Firestore or Cloudinary assets.
class OfflineLibraryService {
  static const String _storageKey = 'noteshub_offline_library_v1';
  final SharedPreferences? _prefsInstance;

  OfflineLibraryService({SharedPreferences? prefs}) : _prefsInstance = prefs;

  SharedPreferences get _prefs {
    if (_prefsInstance != null) return _prefsInstance;
    return LocalStorageService.prefs;
  }

  /// Retrieves all offline documents recorded in local storage.
  Future<List<OfflineDocumentModel>> getDocuments() async {
    final rawJson = _prefs.getString(_storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => OfflineDocumentModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing offline library: $e');
      return [];
    }
  }

  /// Synchronizes the offline library index with physical storage on disk.
  /// Automatically purges records whose physical file was deleted externally.
  Future<List<OfflineDocumentModel>> syncLibraryWithDisk() async {
    final docs = await getDocuments();
    if (kIsWeb) return docs;

    final validDocs = <OfflineDocumentModel>[];
    bool changed = false;

    for (final doc in docs) {
      if (doc.localPath.isNotEmpty) {
        try {
          final file = io.File(doc.localPath);
          if (file.existsSync() && file.lengthSync() > 0) {
            validDocs.add(doc);
            continue;
          }
        } catch (_) {}
      }
      changed = true;
    }

    if (changed) {
      final rawJson = jsonEncode(validDocs.map((d) => d.toMap()).toList());
      await _prefs.setString(_storageKey, rawJson);
    }

    return validDocs;
  }

  /// Checks if a file ID is recorded in the local library.
  Future<bool> isDownloaded(String fileId) async {
    final docs = await getDocuments();
    final match = docs.where((d) => d.id == fileId);
    if (match.isEmpty) return false;

    // On native platforms, confirm the physical file still exists on disk
    if (!kIsWeb) {
      final localPath = match.first.localPath;
      if (localPath.isNotEmpty) {
        try {
          final file = io.File(localPath);
          return file.existsSync();
        } catch (_) {
          return false;
        }
      }
    }

    return true;
  }

  /// Retrieves a specific offline document model by its [fileId].
  Future<OfflineDocumentModel?> getDocument(String fileId) async {
    final docs = await getDocuments();
    final match = docs.where((d) => d.id == fileId);
    return match.isNotEmpty ? match.first : null;
  }

  /// Saves or updates a downloaded document in the local registry.
  Future<void> saveDocument(OfflineDocumentModel document) async {
    final docs = await getDocuments();
    final updatedList = List<OfflineDocumentModel>.from(docs);

    final existingIndex = updatedList.indexWhere((d) => d.id == document.id);
    if (existingIndex >= 0) {
      updatedList[existingIndex] = document;
    } else {
      updatedList.insert(0, document);
    }

    final rawJson = jsonEncode(updatedList.map((d) => d.toMap()).toList());
    await _prefs.setString(_storageKey, rawJson);
  }

  /// Deletes an offline document locally.
  /// REMOVES ONLY THE LOCAL FILE ON DEVICE AND THE LOCAL METADATA ENTRY.
  /// NEVER calls remote Firestore or Cloudinary APIs.
  Future<void> deleteDocument(String fileId) async {
    final docs = await getDocuments();
    final matchIndex = docs.indexWhere((d) => d.id == fileId);

    if (matchIndex < 0) return;

    final docToDelete = docs[matchIndex];

    // 1. Delete physical file on native device if present
    if (!kIsWeb && docToDelete.localPath.isNotEmpty) {
      try {
        final physicalFile = io.File(docToDelete.localPath);
        if (physicalFile.existsSync()) {
          await physicalFile.delete();
        }
      } catch (e) {
        debugPrint('Notice: Local physical file deletion error: $e');
      }
    }

    // 2. Remove entry from local index
    final updatedList = List<OfflineDocumentModel>.from(docs)..removeAt(matchIndex);
    final rawJson = jsonEncode(updatedList.map((d) => d.toMap()).toList());
    await _prefs.setString(_storageKey, rawJson);
  }

  /// Returns the sum of file sizes (in bytes) across all local documents.
  Future<int> getTotalStorageBytes() async {
    final docs = await getDocuments();
    return docs.fold<int>(0, (sum, item) => sum + item.fileSizeBytes);
  }

  /// Clears all offline documents locally.
  Future<void> clearAll() async {
    final docs = await getDocuments();
    if (!kIsWeb) {
      for (final doc in docs) {
        if (doc.localPath.isNotEmpty) {
          try {
            final f = io.File(doc.localPath);
            if (f.existsSync()) await f.delete();
          } catch (_) {}
        }
      }
    }
    await _prefs.remove(_storageKey);
  }
}

