import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/file_model.dart';
import 'package:mobile/core/models/subject_model.dart';
import 'package:mobile/core/utils/acronym_helper.dart';
import 'package:mobile/features/search/logic/search_cubit.dart';
import 'package:mobile/features/search/logic/search_engine.dart';
import 'package:mobile/features/search/logic/search_state.dart';
import 'package:mobile/core/repositories/file_repository.dart';
import 'package:mobile/core/repositories/subject_repository.dart';

// Fake repositories for Cubit test without network/Firebase
class FakeFileRepository extends Fake implements FileRepository {
  @override
  Future<List<FileModel>> getAllFiles() async => [];
}

class FakeSubjectRepository extends Fake implements SubjectRepository {
  @override
  Future<List<SubjectModel>> getAllSubjects() async => [];
}

void main() {
  group('AcronymHelper Tests', () {
    test('generates lowercase acronyms correctly', () {
      expect(AcronymHelper.generate('Web Technology'), equals('wt'));
      expect(AcronymHelper.generate('Operating Systems'), equals('os'));
      expect(AcronymHelper.generate('Database Management Systems'), equals('dms'));
      expect(AcronymHelper.generate('Design and Analysis of Algorithms'), equals('daaoa'));
      expect(AcronymHelper.generate('Mathematics'), equals('m'));
      expect(AcronymHelper.generate(''), equals(''));
      expect(AcronymHelper.generate('   '), equals(''));
    });

    test('tokenizes query strings properly', () {
      expect(
        AcronymHelper.tokenize('  WT   mod  2  '),
        equals(['wt', 'mod', '2']),
      );
      expect(AcronymHelper.tokenize(''), equals([]));
    });
  });

  group('SearchEngine Tests', () {
    final sampleSubjects = [
      const SubjectModel(id: 's1', semester: 4, subject: 1, name: 'Web Technology'),
      const SubjectModel(id: 's2', semester: 4, subject: 2, name: 'Operating Systems'),
      const SubjectModel(id: 's3', semester: 5, subject: 1, name: 'Database Management Systems'),
    ];

    final sampleFiles = [
      const FileModel(
        id: 'f1',
        semester: 4,
        subject: 1,
        module: 2,
        type: 'notes',
        name: 'WT Module 2 Complete Notes.pdf',
        url: 'https://res.cloudinary.com/demo/raw/upload/wt_mod2.pdf',
        publicId: 'notes/wt_mod2',
      ),
      const FileModel(
        id: 'f2',
        semester: 4,
        subject: 1,
        module: 1,
        type: 'qbank',
        name: 'Web Tech Question Bank 2024.pdf',
        url: 'https://res.cloudinary.com/demo/raw/upload/wt_qb1.pdf',
        publicId: 'qbank/wt_qb1',
      ),
      const FileModel(
        id: 'f3',
        semester: 4,
        subject: 2,
        module: 3,
        type: 'notes',
        name: 'CPU Scheduling Algorithms.pdf',
        url: 'https://res.cloudinary.com/demo/raw/upload/os_cpu.pdf',
        publicId: 'notes/os_cpu',
      ),
      const FileModel(
        id: 'f4',
        semester: 5,
        subject: 1,
        module: 1,
        type: 'extra',
        name: 'SQL Cheatsheet & Normalization.pdf',
        url: 'https://res.cloudinary.com/demo/raw/upload/dbms_sql.pdf',
        publicId: 'extra/dbms_sql',
      ),
    ];

    test('finds files by exact or partial file name', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'scheduling',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f3'));
      expect(results.first.subjectDisplayName, equals('Operating Systems'));
    });

    test('finds files by subject name case-insensitively', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'operating systems',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f3'));
    });

    test('finds files by acronym recognition (e.g. "os" matches Operating Systems)', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'os',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f3'));
    });

    test('finds files by subject alias (e.g. "dbms" matches Database Management Systems)', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'dbms',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f4'));
    });

    test('finds files by multi-term combination (e.g. "wt mod 2")', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'wt mod 2',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f1'));
    });

    test('finds files by category name synonym (e.g. "qbank")', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'qbank',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f2'));
    });

    test('filters results by category type filter', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'wt',
        typeFilter: 'notes',
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f1'));
    });

    test('filters results by semester filter', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'module 1',
        semesterFilter: 5,
      );

      expect(results.length, equals(1));
      expect(results.first.file.id, equals('f4'));
    });

    test('returns empty when no documents match terms', () {
      final results = SearchEngine.search(
        files: sampleFiles,
        subjects: sampleSubjects,
        query: 'Quantum Computing',
      );

      expect(results.isEmpty, isTrue);
    });
  });

  group('SearchCubit State Management Tests', () {
    late SearchCubit cubit;

    final sampleSubjects = [
      const SubjectModel(id: 's1', semester: 4, subject: 1, name: 'Web Technology'),
    ];

    final sampleFiles = [
      const FileModel(
        id: 'f1',
        semester: 4,
        subject: 1,
        module: 2,
        type: 'notes',
        name: 'Web Tech Notes.pdf',
        url: 'https://example.com/wt.pdf',
        publicId: 'notes/wt',
      ),
    ];

    setUp(() {
      cubit = SearchCubit(
        fileRepository: FakeFileRepository(),
        subjectRepository: FakeSubjectRepository(),
      );
      cubit.seedData(files: sampleFiles, subjects: sampleSubjects);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state after seeding is SearchLoaded with empty results', () {
      expect(cubit.state, isA<SearchLoaded>());
      final state = cubit.state as SearchLoaded;
      expect(state.results.isEmpty, isTrue);
      expect(state.allFiles.length, equals(1));
    });

    test('setQuery updates search results', () {
      cubit.setQuery('web');
      final state = cubit.state as SearchLoaded;
      expect(state.results.length, equals(1));
      expect(state.results.first.file.id, equals('f1'));
    });

    test('setTypeFilter toggles type filter correctly', () {
      cubit.setQuery('web');
      cubit.setTypeFilter('notes');
      var state = cubit.state as SearchLoaded;
      expect(state.typeFilter, equals('notes'));
      expect(state.results.length, equals(1));

      // Toggling same filter clears it
      cubit.setTypeFilter('notes');
      state = cubit.state as SearchLoaded;
      expect(state.typeFilter, isNull);
    });

    test('clearQuery resets query and results', () {
      cubit.setQuery('web');
      cubit.clearQuery();
      final state = cubit.state as SearchLoaded;
      expect(state.query, isEmpty);
      expect(state.results.isEmpty, isTrue);
    });
  });
}
