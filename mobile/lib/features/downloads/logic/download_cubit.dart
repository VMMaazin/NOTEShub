import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/file_model.dart';
import '../../../core/models/offline_document_model.dart';
import '../../../core/services/download_service.dart';
import '../../../core/services/offline_library_service.dart';
import 'download_state.dart';

class DownloadCubit extends Cubit<DownloadState> {
  final DownloadService _downloadService;
  final OfflineLibraryService _libraryService;

  DownloadCubit({
    required DownloadService downloadService,
    required OfflineLibraryService libraryService,
  })  : _downloadService = downloadService,
        _libraryService = libraryService,
        super(const DownloadState());

  /// Loads all offline documents and calculates storage consumption.
  Future<void> loadLibrary() async {
    emit(state.copyWith(isLoading: true));
    try {
      final allDocs = await _libraryService.syncLibraryWithDisk();
      final totalBytes = await _libraryService.getTotalStorageBytes();

      _applyFilters(
        allDocs: allDocs,
        totalBytes: totalBytes,
        semester: state.semesterFilter,
        query: state.searchQuery,
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load offline documents: ${e.toString()}',
      ));
    }
  }

  /// Initiates download for a [file] and reports live progress.
  Future<void> startDownload(FileModel file, {String? subjectName}) async {
    final fileId = file.id;

    if (state.isFileDownloading(fileId)) return;

    // 1. Mark as active download
    final active = Map<String, double>.from(state.activeDownloads);
    active[fileId] = 0.0;
    emit(state.copyWith(activeDownloads: active, clearError: true));

    try {
      final downloadedDoc = await _downloadService.downloadFile(
        file: file,
        onProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            _updateProgress(fileId, progress);
          }
        },
      );

      // 2. Persist in local library index
      await _libraryService.saveDocument(downloadedDoc);

      // 3. Update library state
      final allDocs = await _libraryService.getDocuments();
      final totalBytes = await _libraryService.getTotalStorageBytes();

      final updatedActive = Map<String, double>.from(state.activeDownloads)..remove(fileId);

      _applyFilters(
        allDocs: allDocs,
        totalBytes: totalBytes,
        activeDownloads: updatedActive,
        semester: state.semesterFilter,
        query: state.searchQuery,
        message: 'Downloaded "${file.name}" for offline study.',
      );
    } catch (e) {
      final updatedActive = Map<String, double>.from(state.activeDownloads)..remove(fileId);
      emit(state.copyWith(
        activeDownloads: updatedActive,
        error: 'Download failed: ${e.toString()}',
      ));
    }
  }

  void _updateProgress(String fileId, double progress) {
    if (!state.activeDownloads.containsKey(fileId)) return;
    final active = Map<String, double>.from(state.activeDownloads);
    active[fileId] = progress;
    emit(state.copyWith(activeDownloads: active));
  }

  /// Cancels an in-progress download.
  void cancelDownload(String fileId) {
    _downloadService.cancelDownload(fileId);
    final active = Map<String, double>.from(state.activeDownloads)..remove(fileId);
    emit(state.copyWith(activeDownloads: active));
  }

  /// Deletes a local offline document.
  /// REMOVES ONLY LOCAL FILE ON DEVICE AND LOCAL METADATA.
  /// NEVER impacts remote Firestore or Cloudinary assets.
  Future<void> deleteOfflineDocument(String fileId) async {
    try {
      await _libraryService.deleteDocument(fileId);
      final allDocs = await _libraryService.getDocuments();
      final totalBytes = await _libraryService.getTotalStorageBytes();

      _applyFilters(
        allDocs: allDocs,
        totalBytes: totalBytes,
        semester: state.semesterFilter,
        query: state.searchQuery,
        message: 'Document removed from local device storage.',
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete local document: $e'));
    }
  }

  /// Clears all downloaded documents from local storage.
  Future<void> clearAll() async {
    try {
      await _libraryService.clearAll();
      _applyFilters(
        allDocs: [],
        totalBytes: 0,
        message: 'All local offline downloads cleared.',
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to clear offline storage: $e'));
    }
  }

  /// Filters displayed documents by semester (or null for all).
  void filterBySemester(int? semester) {
    final newFilter = state.semesterFilter == semester ? null : semester;
    _applyFilters(
      allDocs: state.allDocuments,
      totalBytes: state.totalStorageBytes,
      semester: newFilter,
      query: state.searchQuery,
      clearSemesterFilter: newFilter == null,
    );
  }

  /// Searches through locally downloaded documents.
  void search(String query) {
    _applyFilters(
      allDocs: state.allDocuments,
      totalBytes: state.totalStorageBytes,
      semester: state.semesterFilter,
      query: query.trim(),
    );
  }

  void _applyFilters({
    required List<OfflineDocumentModel> allDocs,
    required int totalBytes,
    Map<String, double>? activeDownloads,
    int? semester,
    bool clearSemesterFilter = false,
    String? query,
    String? message,
  }) {
    var filtered = List<OfflineDocumentModel>.from(allDocs);

    if (semester != null) {
      filtered = filtered.where((d) => d.semester == semester).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      filtered = filtered.where((d) {
        return d.name.toLowerCase().contains(lower) ||
            d.type.toLowerCase().contains(lower) ||
            'semester ${d.semester}'.contains(lower) ||
            'module ${d.module}'.contains(lower);
      }).toList();
    }

    emit(state.copyWith(
      isLoading: false,
      allDocuments: allDocs,
      documents: filtered,
      totalStorageBytes: totalBytes,
      activeDownloads: activeDownloads ?? state.activeDownloads,
      semesterFilter: semester,
      clearSemesterFilter: clearSemesterFilter,
      searchQuery: query ?? state.searchQuery,
      message: message,
      clearError: true,
    ));
  }
}

