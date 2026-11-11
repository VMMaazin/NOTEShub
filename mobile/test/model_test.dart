import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/file_model.dart';
import 'package:mobile/core/models/subject_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/features/auth/bloc/auth_state.dart';

void main() {
  group('UserModel Tests', () {
    test('Correctly deserializes user with admin role', () {
      final data = {
        'name': 'Test Admin',
        'role': 'author',
      };
      final user = UserModel.fromMap(data, 'uid_123');

      expect(user.uid, 'uid_123');
      expect(user.name, 'Test Admin');
      expect(user.role, 'author');
      expect(user.isAuthor, isTrue);
      expect(user.isOwner, isFalse);
      expect(user.isStudent, isFalse);
    });

    test('Correctly deserializes user with owner role', () {
      final data = {
        'name': 'Platform Owner',
        'role': 'owner',
      };
      final user = UserModel.fromMap(data, 'uid_owner');

      expect(user.isOwner, isTrue);
      expect(user.isAuthor, isTrue);
      expect(user.isStudent, isFalse);
    });

    test('Safely handles missing optional fields (defaults to student/guest)', () {
      final user = UserModel.fromMap({}, 'uid_guest');

      expect(user.uid, 'uid_guest');
      expect(user.name, isNull);
      expect(user.role, isNull);
      expect(user.isStudent, isTrue);
      expect(user.isAuthor, isFalse);
      expect(user.isOwner, isFalse);
    });

    test('Serializes to Firestore map', () {
      const user = UserModel(uid: 'uid_1', name: 'Alice', role: 'author');
      final map = user.toFirestore();

      expect(map['name'], 'Alice');
      expect(map['role'], 'author');
    });
  });

  group('SubjectModel Tests', () {
    test('Correctly serializes and deserializes', () {
      final map = {
        'semester': 4,
        'subject': 1,
        'name': 'Web Technology',
      };
      final subject = SubjectModel.fromMap(map, 'sub_doc_1');

      expect(subject.id, 'sub_doc_1');
      expect(subject.semester, 4);
      expect(subject.subject, 1);
      expect(subject.name, 'Web Technology');
      expect(subject.acronym, 'wt');

      final serialized = subject.toFirestore();
      expect(serialized['semester'], 4);
      expect(serialized['subject'], 1);
      expect(serialized['name'], 'Web Technology');
    });

    test('Generates multi-word acronyms correctly', () {
      const s1 = SubjectModel(id: '1', semester: 4, subject: 1, name: 'Operating Systems');
      expect(s1.acronym, 'os');

      const s2 = SubjectModel(id: '2', semester: 5, subject: 2, name: 'Database Management Systems');
      expect(s2.acronym, 'dms');
    });

    test('Throws FormatException when required fields are missing', () {
      expect(
        () => SubjectModel.fromMap({'semester': 4, 'subject': 1}, 'doc_invalid'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FileModel Tests', () {
    test('Correctly serializes and deserializes required fields', () {
      final now = Timestamp.now();
      final map = {
        'semester': 5,
        'subject': 2,
        'module': 1,
        'type': 'notes',
        'name': 'Module 1 - Full Notes.pdf',
        'url': 'https://res.cloudinary.com/debfdnujc/raw/upload/v1/sample.pdf',
        'publicId': 'college_notes/sample',
        'createdAt': now,
      };

      final file = FileModel.fromMap(map, 'file_123');

      expect(file.id, 'file_123');
      expect(file.semester, 5);
      expect(file.subject, 2);
      expect(file.module, 1);
      expect(file.type, 'notes');
      expect(file.name, 'Module 1 - Full Notes.pdf');
      expect(file.publicId, 'college_notes/sample');
      expect(file.isPdf, isTrue);
      expect(
        file.downloadUrl,
        'https://res.cloudinary.com/debfdnujc/raw/upload/fl_attachment/v1/sample.pdf',
      );

      final serialized = file.toFirestore();
      expect(serialized['semester'], 5);
      expect(serialized['publicId'], 'college_notes/sample');
      expect(serialized['createdAt'], now);
    });

    test('Handles missing optional createdAt field safely', () {
      final map = {
        'semester': 4,
        'subject': 1,
        'module': 2,
        'type': 'qbank',
        'name': 'Question Bank 2024.docx',
        'url': 'https://res.cloudinary.com/debfdnujc/raw/upload/v1/qbank.docx',
        'publicId': 'college_notes/qbank',
      };

      final file = FileModel.fromMap(map, 'file_no_date');
      expect(file.createdAt, isNull);
      expect(file.isPdf, isFalse);
    });

    test('Throws FormatException on invalid required fields', () {
      expect(
        () => FileModel.fromMap({
          'semester': 4,
          'subject': 1,
          // Missing module, type, name, url, publicId
        }, 'invalid_file'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Authentication & Student Access Verification', () {
    test('Unauthenticated state represents Student access', () {
      const state = Unauthenticated();
      expect(state, isA<AuthState>());
    });

    test('Authenticated state correctly exposes administrator roles', () {
      const adminState = Authenticated(UserModel(uid: 'admin_1', role: 'author'));
      expect(adminState.isAuthor, isTrue);
      expect(adminState.isOwner, isFalse);

      const ownerState = Authenticated(UserModel(uid: 'owner_1', role: 'owner'));
      expect(ownerState.isAuthor, isTrue);
      expect(ownerState.isOwner, isTrue);

      const studentState = Authenticated(UserModel(uid: 'student_1', role: null));
      expect(studentState.isAuthor, isFalse);
      expect(studentState.isOwner, isFalse);
    });
  });
}

