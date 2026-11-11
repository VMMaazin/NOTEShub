import '../../../core/models/file_model.dart';
import '../../../core/models/subject_model.dart';

/// Aggregates a [FileModel] with its associated [SubjectModel] for search presentation.
class SearchResultItem {
  final FileModel file;
  final SubjectModel? subject;

  const SearchResultItem({
    required this.file,
    this.subject,
  });

  String get subjectDisplayName => subject?.name ?? 'Subject ${file.subject}';

  String get categoryDisplayName {
    switch (file.type.toLowerCase()) {
      case FileCategory.notes:
        return 'Notes';
      case FileCategory.qbank:
        return 'Question Bank';
      case FileCategory.extra:
        return 'Extra Resources';
      default:
        return file.type.toUpperCase();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          runtimeType == other.runtimeType &&
          file.id == other.file.id;

  @override
  int get hashCode => file.id.hashCode;
}
