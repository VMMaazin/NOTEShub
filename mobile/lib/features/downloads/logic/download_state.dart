import '../../../core/models/offline_document_model.dart';
import '../../../core/utils/file_utils.dart';

class DownloadState {
  final List<OfflineDocumentModel> documents;
  final List<OfflineDocumentModel> allDocuments;
  final Map<String, double> activeDownloads;
  final int totalStorageBytes;
  final int? semesterFilter;
  final String searchQuery;
  final bool isLoading;
  final String? message;
  final String? error;

  const DownloadState({
    this.documents = const [],
    this.allDocuments = const [],
    this.activeDownloads = const {},
    this.totalStorageBytes = 0,
    this.semesterFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.message,
    this.error,
  });

  String get formattedTotalStorage => FileUtils.formatBytes(totalStorageBytes);

  bool isFileDownloaded(String fileId) {
    return allDocuments.any((doc) => doc.id == fileId);
  }

  bool isFileDownloading(String fileId) {
    return activeDownloads.containsKey(fileId);
  }

  double? getDownloadProgress(String fileId) {
    return activeDownloads[fileId];
  }

  DownloadState copyWith({
    List<OfflineDocumentModel>? documents,
    List<OfflineDocumentModel>? allDocuments,
    Map<String, double>? activeDownloads,
    int? totalStorageBytes,
    int? semesterFilter,
    bool clearSemesterFilter = false,
    String? searchQuery,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    String? error,
    bool clearError = false,
  }) {
    return DownloadState(
      documents: documents ?? this.documents,
      allDocuments: allDocuments ?? this.allDocuments,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      semesterFilter: clearSemesterFilter ? null : (semesterFilter ?? this.semesterFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

