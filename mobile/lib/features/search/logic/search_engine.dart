import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';
import '../../../core/utils/acronym_helper.dart';
import '../models/search_result_item.dart';

/// Pure algorithmic search engine matching Next.js HomeSearch.tsx with enhanced filtering.
class SearchEngine {
  /// Matches a list of [files] against a [query] and an optional [typeFilter] and [semesterFilter].
  static List<SearchResultItem> search({
    required List<FileModel> files,
    required List<SubjectModel> subjects,
    required String query,
    String? typeFilter,
    int? semesterFilter,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty && typeFilter == null && semesterFilter == null) {
      return const [];
    }

    final terms = AcronymHelper.tokenize(trimmedQuery);

    // If query explicitly specifies a module like "mod 2" or "module 3", extract target module
    final moduleMatch = RegExp(r'\b(?:mod|module|m)\s*([1-5])\b', caseSensitive: false)
        .firstMatch(trimmedQuery);
    final targetModule =
        moduleMatch != null ? int.tryParse(moduleMatch.group(1)!) : null;

    // If query explicitly specifies a semester like "sem 4" or "semester 5", extract target semester
    final semesterMatch =
        RegExp(r'\b(?:sem|semester|s)\s*([1-8])\b', caseSensitive: false)
            .firstMatch(trimmedQuery);
    final targetSemesterFromQuery =
        semesterMatch != null ? int.tryParse(semesterMatch.group(1)!) : null;

    // Map subjects by semester + subject ID for rapid lookup
    final subjectMap = <String, SubjectModel>{};
    for (final s in subjects) {
      subjectMap['${s.semester}_${s.subject}'] = s;
    }

    final results = <SearchResultItem>[];

    for (final file in files) {
      // 1. Check optional programmatic type filter
      if (typeFilter != null &&
          typeFilter.isNotEmpty &&
          file.type.toLowerCase() != typeFilter.toLowerCase()) {
        continue;
      }

      // 2. Check programmatic semester filter
      if (semesterFilter != null && file.semester != semesterFilter) {
        continue;
      }

      // 3. Check query-extracted semester
      if (targetSemesterFromQuery != null &&
          file.semester != targetSemesterFromQuery) {
        continue;
      }

      // 4. Check query-extracted module
      if (targetModule != null && file.module != targetModule) {
        continue;
      }

      final subject = subjectMap['${file.semester}_${file.subject}'];
      final subjectName = subject?.name.toLowerCase() ?? '';
      String subjectAcronym =
          subject != null ? AcronymHelper.generate(subject.name) : '';

      // Standard CS curriculum acronym aliases
      if (subjectName.contains('database') &&
          subjectName.contains('management')) {
        subjectAcronym += ' dbms';
      }
      if (subjectName.contains('computer') &&
          subjectName.contains('network')) {
        subjectAcronym += ' cn';
      }
      if (subjectName.contains('algorithm')) {
        subjectAcronym += ' daa';
      }

      final fileName = file.name.toLowerCase();
      final typeStr = file.type.toLowerCase();

      // Extended category tokens for high recall
      String categoryTokens = typeStr;
      if (typeStr == FileCategory.qbank) {
        categoryTokens += ' qbank question bank questions qb pyq';
      } else if (typeStr == FileCategory.notes) {
        categoryTokens += ' notes note lecture study';
      } else if (typeStr == FileCategory.extra) {
        categoryTokens += ' extra resources resource reference text';
      }

      final moduleStr =
          'module ${file.module} mod ${file.module} m${file.module} ${file.module}';
      final semesterStr =
          'semester ${file.semester} sem ${file.semester} s${file.semester}';

      // If query terms exist, all terms must match at least one attribute of the file
      if (terms.isNotEmpty) {
        final matchesAll = terms.every((term) {
          return fileName.contains(term) ||
              subjectName.contains(term) ||
              subjectAcronym == term ||
              subjectAcronym.contains(term) ||
              categoryTokens.contains(term) ||
              moduleStr.contains(term) ||
              semesterStr.contains(term);
        });

        if (!matchesAll) continue;
      }

      results.add(SearchResultItem(file: file, subject: subject));
    }

    return results;
  }
}
