import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../models/search_result_item.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final String query;
  final String? typeFilter;
  final int? semesterFilter;
  final List<SearchResultItem> results;
  final List<FileModel> allFiles;
  final List<SubjectModel> allSubjects;
  final bool isInitialEmpty;

  const SearchLoaded({
    required this.query,
    this.typeFilter,
    this.semesterFilter,
    required this.results,
    required this.allFiles,
    required this.allSubjects,
    this.isInitialEmpty = false,
  });

  SearchLoaded copyWith({
    String? query,
    String? typeFilter,
    int? semesterFilter,
    bool clearTypeFilter = false,
    bool clearSemesterFilter = false,
    List<SearchResultItem>? results,
    List<FileModel>? allFiles,
    List<SubjectModel>? allSubjects,
    bool? isInitialEmpty,
  }) {
    return SearchLoaded(
      query: query ?? this.query,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      semesterFilter: clearSemesterFilter ? null : (semesterFilter ?? this.semesterFilter),
      results: results ?? this.results,
      allFiles: allFiles ?? this.allFiles,
      allSubjects: allSubjects ?? this.allSubjects,
      isInitialEmpty: isInitialEmpty ?? this.isInitialEmpty,
    );
  }
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);
}
