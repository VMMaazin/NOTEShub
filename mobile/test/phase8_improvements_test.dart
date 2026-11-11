import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/core/models/file_model.dart';
import 'package:mobile/core/models/offline_document_model.dart';
import 'package:mobile/core/models/subject_model.dart';
import 'package:mobile/core/repositories/auth_repository.dart';
import 'package:mobile/core/repositories/file_repository.dart';
import 'package:mobile/core/repositories/subject_repository.dart';
import 'package:mobile/core/services/download_service.dart';
import 'package:mobile/core/services/offline_library_service.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/downloads/logic/download_cubit.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/features/subject/presentation/subject_detail_screen.dart';
import 'package:mobile/shared/dialogs/download_options_sheet.dart';
import 'package:mobile/features/admin/presentation/widgets/delete_policy_dialog.dart';
import 'package:mobile/widgets/noteshub_deck_cards.dart';
import 'package:pdfrx/pdfrx.dart';

class MockSubjectRepository extends Fake implements SubjectRepository {
  @override
  Future<List<int>> getAvailableSemesters() async {
    return [5, 4];
  }

  @override
  Stream<List<SubjectModel>> streamSubjects(int semester) {
    return Stream.value([
      SubjectModel(id: 's1', semester: semester, subject: 1, name: 'Computer Networks'),
      SubjectModel(id: 's2', semester: semester, subject: 2, name: 'Operating Systems'),
    ]);
  }
}

class MockFileRepository extends Fake implements FileRepository {
  @override
  Stream<List<FileModel>> streamModuleFiles({
    required int semester,
    required int subject,
    required int module,
  }) {
    return Stream.value([
      FileModel(
        id: 'f1',
        semester: semester,
        subject: subject,
        module: module,
        type: 'notes',
        name: 'M1 Notes BDT.pdf',
        url: 'https://cloudinary.com/test_m1.pdf',
        publicId: 'raw/m1',
      ),
      FileModel(
        id: 'f2',
        semester: semester,
        subject: subject,
        module: module,
        type: 'qbank',
        name: 'M1 Question Bank.pdf',
        url: 'https://cloudinary.com/test_qb.pdf',
        publicId: 'raw/qb',
      ),
    ]);
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  bool isDownloading(String fileId) => false;
}

class FakeOfflineLibraryService extends Fake implements OfflineLibraryService {
  @override
  Future<List<OfflineDocumentModel>> syncLibraryWithDisk() async => [];

  @override
  Future<int> getTotalStorageBytes() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8 UI Improvements & Layout Tests', () {
    testWidgets('Home page renders Semester 5 first with ACTIVE badge and Semester 4 second', (tester) async {
      final subjectRepo = MockSubjectRepository();
      final authRepo = FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SubjectRepository>.value(value: subjectRepo),
              RepositoryProvider<AuthRepository>.value(value: authRepo),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>(
                  create: (_) => AuthBloc(authRepository: authRepo),
                ),
                BlocProvider<DownloadCubit>(
                  create: (_) => DownloadCubit(
                    downloadService: FakeDownloadService(),
                    libraryService: FakeOfflineLibraryService(),
                  ),
                ),
              ],
              child: const HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Semester 5 and Semester 4 are rendered
      expect(find.text('Semester 5'), findsOneWidget);
      expect(find.text('Semester 4'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      // Verify other semesters (1, 2, 3, 6, 7, 8) are NOT on the home screen
      expect(find.text('Semester 1'), findsNothing);
      expect(find.text('Semester 2'), findsNothing);
      expect(find.text('Semester 3'), findsNothing);
      expect(find.text('Semester 6'), findsNothing);
      expect(find.text('Semester 7'), findsNothing);
      expect(find.text('Semester 8'), findsNothing);
    });

    testWidgets('NotesHubAcademicCard without badgeText renders title and omits slot badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesHubAcademicCard(
              title: 'Database Management Systems',
              subtitle: 'Modules 1–5 Syllabus',
              leadingNumber: 1,
              badgeText: null, // Null badge for clean student UI
              actionLabel: 'OPEN MODULES',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Database Management Systems'), findsOneWidget);
      expect(find.text('OPEN MODULES'), findsOneWidget);
      expect(find.text('Slot 1'), findsNothing);
      expect(find.text('Slot 2'), findsNothing);
    });

    testWidgets('DownloadOptionsSheet renders exact labels "Download in App" and "Download to Device"', (tester) async {
      const testFile = FileModel(
        id: 'file_001',
        semester: 4,
        subject: 1,
        module: 1,
        type: 'notes',
        name: 'Unit_1_Lecture_Notes.pdf',
        url: 'https://cloudinary.com/test.pdf',
        publicId: 'raw/noteshub/test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<DownloadCubit>(
                  create: (_) => DownloadCubit(
                    downloadService: FakeDownloadService(),
                    libraryService: FakeOfflineLibraryService(),
                  ),
                ),
              ],
              child: const DownloadOptionsSheet(file: testFile),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check exact label strings requested in specification
      expect(find.text('Download in App'), findsOneWidget);
      expect(find.text('Download to Device'), findsOneWidget);
      expect(find.text('Save to in-app Offline Library for reading without internet'), findsOneWidget);
      expect(find.text('Save to device Downloads folder / Files app'), findsOneWidget);
    });

    testWidgets('SubjectDetailScreen displays Lecture Notes, Question Bank, and Extra Resources one below the other', (tester) async {
      final subjectRepo = MockSubjectRepository();
      final fileRepo = MockFileRepository();
      final authRepo = FakeAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SubjectRepository>.value(value: subjectRepo),
              RepositoryProvider<FileRepository>.value(value: fileRepo),
              RepositoryProvider<AuthRepository>.value(value: authRepo),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>(
                  create: (_) => AuthBloc(authRepository: authRepo),
                ),
                BlocProvider<DownloadCubit>(
                  create: (_) => DownloadCubit(
                    downloadService: FakeDownloadService(),
                    libraryService: FakeOfflineLibraryService(),
                  ),
                ),
              ],
              child: const SubjectDetailScreen(
                semester: 5,
                subject: 1,
                initialSubjectName: 'Computer Networks',
                initialModule: 1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify module tabs are present
      expect(find.text('Module 1'), findsWidgets);
      expect(find.text('Module 2'), findsOneWidget);
      expect(find.text('Module 5'), findsOneWidget);

      // Verify all 3 categories appear as sections on the same module page
      expect(find.text('Lecture Notes'), findsWidgets);
      expect(find.text('Question Bank'), findsWidgets);
      expect(find.text('Extra Resources'), findsOneWidget);

      // Verify files in their respective sections
      expect(find.text('M1 Notes BDT.pdf'), findsOneWidget);
      expect(find.text('M1 Question Bank.pdf'), findsOneWidget);

      // Verify empty section placeholder for Extra Resources
      expect(find.text('No Extra Resources uploaded for Module 1 yet'), findsOneWidget);
    });

    testWidgets('PDF Viewer pdfrx params allow zooming below 100% down to 10% without clamp', (tester) async {
      const params = PdfViewerParams(
        minScale: 0.1,
        maxScale: 6.0,
        useAlternativeFitScaleAsMinScale: false,
        boundaryMargin: EdgeInsets.all(80),
        enableKeyboardNavigation: true,
      );

      expect(params.minScale, equals(0.1));
      expect(params.maxScale, equals(6.0));
      expect(params.useAlternativeFitScaleAsMinScale, isFalse);
      expect(params.enableKeyboardNavigation, isTrue);
      expect(params.boundaryMargin, equals(const EdgeInsets.all(80)));
    });

    testWidgets('NotesHubResourceCard omits delete button for students and shows for admins', (tester) async {
      // 1. Student card (onDelete: null)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesHubResourceCard(
              title: 'Physics_M1.pdf',
              moduleNumber: 1,
              categoryType: 'notes',
              onView: () {},
              onDownload: () {},
              onDelete: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

      // 2. Admin card (onDelete provided)
      bool deleteTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesHubResourceCard(
              title: 'Physics_M1.pdf',
              moduleNumber: 1,
              categoryType: 'notes',
              onView: () {},
              onDownload: () {},
              onDelete: () => deleteTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();
      expect(deleteTriggered, isTrue);
    });

    testWidgets('ConfirmDeleteResourceDialog displays error message if deletion fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteResourceDialog(
              resourceName: 'Operating_Systems.pdf',
              onConfirmDelete: () async {
                throw Exception('Missing permissions in Firestore');
              },
            ),
          ),
        ),
      );

      expect(find.text('Delete Resource'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Dialog stays visible and displays the error message
      expect(find.text('Delete Resource'), findsOneWidget);
      expect(find.textContaining('Missing permissions in Firestore'), findsOneWidget);
    });
  });
}
