import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/models/file_model.dart';
import 'package:mobile/core/models/offline_document_model.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/download_service.dart';
import 'package:mobile/core/services/offline_library_service.dart';
import 'package:mobile/core/utils/file_utils.dart';
import 'package:mobile/features/downloads/logic/download_cubit.dart';

// Fake DownloadService that simulates network download without real HTTP
class FakeDownloadService extends Fake implements DownloadService {
  final Map<String, bool> active = {};

  @override
  bool isDownloading(String fileId) => active[fileId] ?? false;

  @override
  Future<OfflineDocumentModel> downloadFile({
    required FileModel file,
    Function(int received, int total)? onProgress,
  }) async {
    if (active[file.id] == true) {
      throw StateError('Download is already in progress for "${file.name}".');
    }
    active[file.id] = true;

    if (onProgress != null) {
      onProgress(50, 100);
      onProgress(100, 100);
    }

    active[file.id] = false;

    return OfflineDocumentModel.fromFileModel(
      file: file,
      localPath: '/mock/path/${file.id}.pdf',
      fileSizeBytes: 1024 * 1024 * 2, // 2.0 MB
      downloadedAt: DateTime.now(),
    );
  }

  @override
  void cancelDownload(String fileId) {
    active[fileId] = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileUtils Tests', () {
    test('sanitizes filenames safely removing illegal filesystem characters', () {
      expect(
        FileUtils.sanitizeFileName('Module 1: Intro/Overview *2024*?.pdf'),
        equals('Module 1_ Intro_Overview _2024_.pdf'),
      );
      expect(
        FileUtils.sanitizeFileName('Operating Systems Notes'),
        equals('Operating Systems Notes.pdf'),
      );
      expect(
        FileUtils.sanitizeFileName(''),
        equals('document.pdf'),
      );
    });

    test('formats byte sizes correctly', () {
      expect(FileUtils.formatBytes(0), equals('0 B'));
      expect(FileUtils.formatBytes(512), equals('512 B'));
      expect(FileUtils.formatBytes(1024 * 500), equals('500.0 KB'));
      expect(FileUtils.formatBytes(1024 * 1024 * 3), equals('3.0 MB'));
    });

    test('validates PDF magic bytes correctly', () {
      expect(FileUtils.hasPdfSignature([0x25, 0x50, 0x44, 0x46, 0x2D]), isTrue);
      expect(FileUtils.hasPdfSignature([0x89, 0x50, 0x4E, 0x47]), isFalse);
      expect(FileUtils.hasPdfSignature([0x25]), isFalse);
    });
  });

  group('ApiClient URL Transformation Tests', () {
    const rawUrl = 'https://res.cloudinary.com/debfdnujc/raw/upload/v1/notes/sem4/notes.pdf';
    const attachmentUrl = 'https://res.cloudinary.com/debfdnujc/raw/upload/fl_attachment/v1/notes/sem4/notes.pdf';

    test('getAttachmentUrl converts raw upload URL to attachment URL', () {
      final converted = ApiClient.getAttachmentUrl(rawUrl);
      expect(converted, equals(attachmentUrl));
    });

    test('getAttachmentUrl does not duplicate fl_attachment if already present', () {
      final converted = ApiClient.getAttachmentUrl(attachmentUrl);
      expect(converted, equals(attachmentUrl));
    });

    test('getRawStreamingUrl strips fl_attachment for inline in-app PDF viewing', () {
      final stripped = ApiClient.getRawStreamingUrl(attachmentUrl);
      expect(stripped, equals(rawUrl));
    });
  });

  group('OfflineDocumentModel Tests', () {
    final sampleFile = const FileModel(
      id: 'doc_123',
      semester: 4,
      subject: 1,
      module: 2,
      type: 'notes',
      name: 'WT Module 2 Notes.pdf',
      url: 'https://res.cloudinary.com/demo/raw/upload/wt_mod2.pdf',
      publicId: 'notes/wt_mod2',
    );

    test('creates offline model from FileModel and serializes to map and json', () {
      final offlineDoc = OfflineDocumentModel.fromFileModel(
        file: sampleFile,
        localPath: '/data/user/0/noteshub/wt_mod2.pdf',
        fileSizeBytes: 2048000,
      );

      expect(offlineDoc.id, equals('doc_123'));
      expect(offlineDoc.name, equals('WT Module 2 Notes.pdf'));
      expect(offlineDoc.formattedSize, equals('2.0 MB'));

      final jsonStr = offlineDoc.toJson();
      final restored = OfflineDocumentModel.fromJson(jsonStr);

      expect(restored.id, equals(offlineDoc.id));
      expect(restored.localPath, equals(offlineDoc.localPath));
      expect(restored.fileSizeBytes, equals(2048000));
    });

    test('converts offline model back to FileModel faithfully', () {
      final offlineDoc = OfflineDocumentModel.fromFileModel(
        file: sampleFile,
        localPath: '/data/path.pdf',
        fileSizeBytes: 1024,
      );

      final fileModel = offlineDoc.toFileModel();
      expect(fileModel.id, equals(sampleFile.id));
      expect(fileModel.semester, equals(4));
      expect(fileModel.type, equals('notes'));
    });
  });

  group('OfflineLibraryService Tests', () {
    late SharedPreferences prefs;
    late OfflineLibraryService service;

    final sampleDoc = OfflineDocumentModel(
      id: 'doc_1',
      name: 'OS Lecture 1.pdf',
      semester: 4,
      subject: 2,
      module: 1,
      type: 'notes',
      url: 'https://example.com/os1.pdf',
      publicId: 'notes/os1',
      localPath: '/mock/os1.pdf',
      fileSizeBytes: 1048576, // 1.0 MB
      downloadedAt: DateTime.now(),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = OfflineLibraryService(prefs: prefs);
    });

    test('starts with an empty offline library', () async {
      final docs = await service.getDocuments();
      expect(docs.isEmpty, isTrue);
      expect(await service.getTotalStorageBytes(), equals(0));
    });

    test('saves document and updates storage calculation', () async {
      await service.saveDocument(sampleDoc);

      final docs = await service.getDocuments();
      expect(docs.length, equals(1));
      expect(docs.first.id, equals('doc_1'));
      expect(await service.getTotalStorageBytes(), equals(1048576));
    });

    test('deletes local document from library registry', () async {
      await service.saveDocument(sampleDoc);
      expect((await service.getDocuments()).length, equals(1));

      await service.deleteDocument('doc_1');
      expect((await service.getDocuments()).isEmpty, isTrue);
      expect(await service.getTotalStorageBytes(), equals(0));
    });

    test('clears all documents from offline library', () async {
      await service.saveDocument(sampleDoc);
      await service.clearAll();
      expect((await service.getDocuments()).isEmpty, isTrue);
    });
  });

  group('DownloadCubit State Management Tests', () {
    late SharedPreferences prefs;
    late OfflineLibraryService libraryService;
    late FakeDownloadService downloadService;
    late DownloadCubit cubit;

    final sampleFile = const FileModel(
      id: 'file_99',
      semester: 5,
      subject: 1,
      module: 3,
      type: 'qbank',
      name: 'DBMS Question Bank 2024.pdf',
      url: 'https://example.com/dbms.pdf',
      publicId: 'qbank/dbms',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      libraryService = OfflineLibraryService(prefs: prefs);
      downloadService = FakeDownloadService();

      cubit = DownloadCubit(
        downloadService: downloadService,
        libraryService: libraryService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has empty downloads', () {
      expect(cubit.state.documents.isEmpty, isTrue);
      expect(cubit.state.activeDownloads.isEmpty, isTrue);
    });

    test('startDownload updates progress and saves to library', () async {
      await cubit.startDownload(sampleFile);

      expect(cubit.state.isFileDownloaded('file_99'), isTrue);
      expect(cubit.state.allDocuments.length, equals(1));
      expect(cubit.state.totalStorageBytes, equals(1024 * 1024 * 2));
    });

    test('filterBySemester filters local offline documents correctly', () async {
      await cubit.startDownload(sampleFile); // Semester 5

      cubit.filterBySemester(4);
      expect(cubit.state.documents.isEmpty, isTrue);

      cubit.filterBySemester(5);
      expect(cubit.state.documents.length, equals(1));

      // Reset
      cubit.filterBySemester(5);
      expect(cubit.state.documents.length, equals(1));
    });

    test('search filters local documents by keyword', () async {
      await cubit.startDownload(sampleFile);

      cubit.search('Question Bank');
      expect(cubit.state.documents.length, equals(1));

      cubit.search('Compiler Design');
      expect(cubit.state.documents.isEmpty, isTrue);
    });

    test('deleteOfflineDocument removes document locally', () async {
      await cubit.startDownload(sampleFile);
      expect(cubit.state.allDocuments.length, equals(1));

      await cubit.deleteOfflineDocument('file_99');
      expect(cubit.state.allDocuments.isEmpty, isTrue);
      expect(cubit.state.isFileDownloaded('file_99'), isFalse);
    });
  });
}
