import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/repositories/file_repository.dart';
import 'package:mobile/core/repositories/subject_repository.dart';
import 'package:mobile/core/services/cloudinary_upload_service.dart';
import 'package:mobile/core/utils/file_utils.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:mobile/features/admin/presentation/widgets/delete_policy_dialog.dart';
import 'package:mobile/features/pdf_viewer/presentation/pdf_viewer_screen.dart';

void main() {
  group('Admin Role Gating & UserModel Tests', () {
    test('Owner role yields isOwner=true and isAuthor=true', () {
      const user = UserModel(uid: 'regular_uid', role: 'owner', name: 'Admin One');
      expect(user.isOwner, isTrue);
      expect(user.isAuthor, isTrue);
      expect(user.isStudent, isFalse);
    });

    test('Hardcoded ownerUid fallback grants owner & author access even with null role', () {
      const user = UserModel(uid: UserModel.ownerUid, role: null, name: 'Root Owner');
      expect(user.isOwner, isTrue);
      expect(user.isAuthor, isTrue);
      expect(user.isStudent, isFalse);
    });

    test('Author role yields isAuthor=true but isOwner=false', () {
      const user = UserModel(uid: 'some_uid', role: 'author', name: 'Author One');
      expect(user.isAuthor, isTrue);
      expect(user.isOwner, isFalse);
      expect(user.isStudent, isFalse);
    });

    test('Unassigned role yields isStudent=true and isAuthor=false', () {
      const user = UserModel(uid: 'guest_uid', role: null);
      expect(user.isAuthor, isFalse);
      expect(user.isOwner, isFalse);
      expect(user.isStudent, isTrue);
    });

    test('Unknown or student role yields isStudent=true and isAuthor=false', () {
      const user = UserModel(uid: 'student_uid', role: 'student');
      expect(user.isAuthor, isFalse);
      expect(user.isOwner, isFalse);
      expect(user.isStudent, isTrue);
    });
  });

  group('CloudinaryUploadService Validation Tests', () {
    final validPdfBytes = utf8.encode('%PDF-1.4 test content for academic upload');

    test('Valid PDF file passes validation without error', () {
      expect(
        () => CloudinaryUploadService.validatePdfFile(
          fileBytes: validPdfBytes,
          fileName: 'Module1_Notes.pdf',
        ),
        returnsNormally,
      );
    });

    test('Empty bytes throw ArgumentError', () {
      expect(
        () => CloudinaryUploadService.validatePdfFile(
          fileBytes: [],
          fileName: 'Notes.pdf',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('empty'),
        )),
      );
    });

    test('Non-PDF extension throws ArgumentError', () {
      expect(
        () => CloudinaryUploadService.validatePdfFile(
          fileBytes: validPdfBytes,
          fileName: 'Notes.docx',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('.pdf'),
        )),
      );
    });

    test('Missing %PDF signature throws ArgumentError', () {
      final fakeBytes = utf8.encode('NOT_A_PDF content text here');
      expect(
        () => CloudinaryUploadService.validatePdfFile(
          fileBytes: fakeBytes,
          fileName: 'Fake.pdf',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('%PDF'),
        )),
      );
    });

    test('Oversized document (> 50MB) throws ArgumentError', () {
      // Mock list length by subclassing or large allocation simulation
      final oversizedBytes = List<int>.filled(50 * 1024 * 1024 + 10, 0);
      oversizedBytes[0] = 0x25; // %
      oversizedBytes[1] = 0x50; // P
      oversizedBytes[2] = 0x44; // D
      oversizedBytes[3] = 0x46; // F
      oversizedBytes[4] = 0x2D; // -

      expect(
        () => CloudinaryUploadService.validatePdfFile(
          fileBytes: oversizedBytes,
          fileName: 'Huge.pdf',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('exceeds the maximum allowed limit'),
        )),
      );
    });
  });

  group('Subject & File Validation Logic Tests', () {
    test('saveSubjectName throws on empty or whitespace name', () {
      final repo = SubjectRepository();
      expect(
        () => repo.saveSubjectName(semester: 4, subjectId: 1, newName: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addSubject rejects invalid semester bounds', () {
      final repo = SubjectRepository();
      expect(
        () => repo.addSubject(semester: 0, subjectId: 1, name: 'Math'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'msg', contains('Semester'))),
      );
      expect(
        () => repo.addSubject(semester: 9, subjectId: 1, name: 'Math'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'msg', contains('Semester'))),
      );
    });

    test('addSubject rejects invalid subject slot bounds', () {
      final repo = SubjectRepository();
      expect(
        () => repo.addSubject(semester: 4, subjectId: 0, name: 'Math'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'msg', contains('Subject slot'))),
      );
      expect(
        () => repo.addSubject(semester: 4, subjectId: 9, name: 'Math'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'msg', contains('Subject slot'))),
      );
    });

    test('addSubject rejects empty subject name', () {
      final repo = SubjectRepository();
      expect(
        () => repo.addSubject(semester: 4, subjectId: 1, name: '  '),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'msg', contains('cannot be empty'))),
      );
    });

    test('updateFileName rejects empty name', () {
      final repo = FileRepository();
      expect(
        () => repo.updateFileName(docId: 'doc_1', newName: ' '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('FileUtils sanitizes path traversal attempts and illegal characters', () {
      expect(FileUtils.sanitizeFileName('../../../etc/passwd.pdf'), equals('_.._.._etc_passwd.pdf'));
      expect(FileUtils.sanitizeFileName('notes/week:1*?.pdf'), equals('notes_week_1_.pdf'));
      expect(FileUtils.sanitizeFileName('plain_document'), equals('plain_document.pdf'));
    });

    test('FileUtils formats bytes accurately', () {
      expect(FileUtils.formatBytes(0), equals('0 B'));
      expect(FileUtils.formatBytes(1024), equals('1.0 KB'));
      expect(FileUtils.formatBytes(2 * 1024 * 1024), equals('2.0 MB'));
    });

    test('FileUtils correctly identifies valid and invalid PDF headers', () {
      expect(FileUtils.hasPdfSignature([0x25, 0x50, 0x44, 0x46]), isTrue);
      expect(FileUtils.hasPdfSignature([0x89, 0x50, 0x4E, 0x47]), isFalse); // PNG header
      expect(FileUtils.hasPdfSignature([]), isFalse);
    });
  });

  group('Admin Widgets Tests', () {
    testWidgets('AdminStatCard renders label, value, and triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminStatCard(
              label: 'Total Files',
              value: '142',
              icon: Icons.file_copy,
              accentColor: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Total Files'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.byIcon(Icons.file_copy), findsOneWidget);

      await tester.tap(find.text('Total Files'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('ConfirmDeleteResourceDialog renders confirmation and executes deletion', (tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteResourceDialog(
              resourceName: 'DBMS_Module1.pdf',
              onConfirmDelete: () async {
                deleteCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Delete Resource'), findsOneWidget);
      expect(find.textContaining('DBMS_Module1.pdf'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('PdfViewerScreen renders error screen gracefully when document URL is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PdfViewerScreen(
            title: 'Sample Test Document',
            pdfUrl: '',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sample Test Document'), findsOneWidget);
      expect(find.text('Could not open PDF'), findsOneWidget);
      expect(find.text('No document URL was provided.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

