import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Repository for handling Firebase Authentication and role resolution from Firestore.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of current Firebase Auth state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently logged in Firebase User, if any.
  User? get currentUser => _auth.currentUser;

  /// Retrieves user profile and administrative role from `users/{uid}`.
  ///
  /// Safe: If the document is missing or errors occur, returns a [UserModel]
  /// with null role (resolving to student/guest privileges).
  Future<UserModel> getUserProfile(String uid) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();

      if (!docSnap.exists || docSnap.data() == null) {
        // Safe default: No administrative role
        return UserModel(uid: uid, role: null, name: null);
      }

      return UserModel.fromFirestore(docSnap);
    } catch (e) {
      // In case of network/offline issues, safe fallback to guest
      return UserModel(uid: uid, role: null, name: null);
    }
  }

  /// Streams the authenticated user's profile with real-time role updates.
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserModel(uid: uid, role: null, name: null);
      }
      return UserModel.fromFirestore(snapshot);
    });
  }

  /// Signs in using email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs out of Firebase Authentication.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email matching Next.js functionality.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

