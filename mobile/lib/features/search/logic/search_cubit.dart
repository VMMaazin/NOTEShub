import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/repositories/file_repository.dart';
import '../../../core/repositories/subject_repository.dart';
import 'search_engine.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final FileRepository _fileRepository;
  final SubjectRepository _subjectRepository;

  List<FileModel> _cachedFiles = [];
  List<SubjectModel> _cachedSubjects = [];
  bool _isDataLoaded = false;

  SearchCubit({
    required FileRepository fileRepository,
    required SubjectRepository subjectRepository,
  })  : _fileRepository = fileRepository,
        _subjectRepository = subjectRepository,
        super(const SearchInitial());

  /// Seeds or preloads cache directly (useful for tests or instant loading)
  void seedData({
    required List<FileModel> files,
    required List<SubjectModel> subjects,
  }) {
    _cachedFiles = List.from(files);
    _cachedSubjects = List.from(subjects);
    _isDataLoaded = true;
    emit(SearchLoaded(
      query: '',
      results: const [],
      allFiles: _cachedFiles,
      allSubjects: _cachedSubjects,
      isInitialEmpty: true,
    ));
  }

  /// Loads subjects and files from Firestore into memory cache
  Future<void> loadCache() async {
    if (_isDataLoaded) return;

    emit(const SearchLoading());
    try {
      final results = await Future.wait([
        _fileRepository.getAllFiles(),
        _subjectRepository.getAllSubjects(),
      ]);

      _cachedFiles = results[0] as List<FileModel>;
      _cachedSubjects = results[1] as List<SubjectModel>;
      _isDataLoaded = true;

      emit(SearchLoaded(
        query: '',
        results: const [],
        allFiles: _cachedFiles,
        allSubjects: _cachedSubjects,
        isInitialEmpty: true,
      ));
    } catch (e) {
      emit(SearchError('Failed to load study materials: ${e.toString()}'));
    }
  }

  /// Executes filtered search
  void setQuery(String query) {
    if (state is! SearchLoaded) {
      if (!_isDataLoaded) {
        loadCache().then((_) => setQuery(query));
        return;
      }
    }

    final currentState = state is SearchLoaded
        ? state as SearchLoaded
        : SearchLoaded(
            query: '',
            results: const [],
            allFiles: _cachedFiles,
            allSubjects: _cachedSubjects,
            isInitialEmpty: true,
          );

    final trimmed = query.trim();
    if (trimmed.isEmpty &&
        currentState.typeFilter == null &&
        currentState.semesterFilter == null) {
      emit(currentState.copyWith(
        query: query,
        results: const [],
        isInitialEmpty: true,
      ));
      return;
    }

    final searchResults = SearchEngine.search(
      files: _cachedFiles,
      subjects: _cachedSubjects,
      query: query,
      typeFilter: currentState.typeFilter,
      semesterFilter: currentState.semesterFilter,
    );

    emit(currentState.copyWith(
      query: query,
      results: searchResults,
      isInitialEmpty: trimmed.isEmpty && searchResults.isEmpty,
    ));
  }

  void setTypeFilter(String? typeFilter) {
    if (state is! SearchLoaded) return;
    final currentState = state as SearchLoaded;

    final isSame = currentState.typeFilter == typeFilter;
    final newFilter = isSame ? null : typeFilter;

    final searchResults = SearchEngine.search(
      files: _cachedFiles,
      subjects: _cachedSubjects,
      query: currentState.query,
      typeFilter: newFilter,
      semesterFilter: currentState.semesterFilter,
    );

    emit(currentState.copyWith(
      typeFilter: newFilter,
      clearTypeFilter: newFilter == null,
      results: searchResults,
      isInitialEmpty: currentState.query.trim().isEmpty && newFilter == null,
    ));
  }

  void setSemesterFilter(int? semesterFilter) {
    if (state is! SearchLoaded) return;
    final currentState = state as SearchLoaded;

    final isSame = currentState.semesterFilter == semesterFilter;
    final newFilter = isSame ? null : semesterFilter;

    final searchResults = SearchEngine.search(
      files: _cachedFiles,
      subjects: _cachedSubjects,
      query: currentState.query,
      typeFilter: currentState.typeFilter,
      semesterFilter: newFilter,
    );

    emit(currentState.copyWith(
      semesterFilter: newFilter,
      clearSemesterFilter: newFilter == null,
      results: searchResults,
      isInitialEmpty: currentState.query.trim().isEmpty && newFilter == null,
    ));
  }

  void clearQuery() {
    setQuery('');
  }
}
