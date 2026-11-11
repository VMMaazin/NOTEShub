import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final firebaseUser = event.user;

    if (firebaseUser == null) {
      // Students/Guests browse unauthenticated
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());

    try {
      // Resolve role from Firestore `users/{uid}`
      final userProfile = await _authRepository.getUserProfile(firebaseUser.uid);
      if (!userProfile.isAuthor) {
        // Reject unknown, student, or missing roles from admin session
        await _authRepository.signOut();
        emit(const Unauthenticated());
        return;
      }
      emit(Authenticated(userProfile));
    } catch (_) {
      // Reject any failed profile resolution gracefully and fall back to public student mode
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final credential = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final user = credential.user;
      if (user != null) {
        final profile = await _authRepository.getUserProfile(user.uid);
        if (!profile.isAuthor) {
          // Strict gate: only 'owner' and 'author' roles are permitted
          await _authRepository.signOut();
          emit(const AuthFailure(
            'Access denied: Your account does not have an author or owner role.',
          ));
          return;
        }
        emit(Authenticated(profile));
      } else {
        emit(const Unauthenticated());
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'network-request-failed':
          message = 'Network error: Please check your internet connection.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = 'Authentication failed. Please verify your credentials.';
      }
      emit(AuthFailure(message));
    } catch (_) {
      emit(const AuthFailure('An unexpected error occurred during sign in. Please try again.'));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
    } catch (_) {
      // In case of network interruption, ensure local client session is discarded
    } finally {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(PasswordResetSent(event.email));
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No user found with this email address.',
        'invalid-email' => 'Please enter a valid email address.',
        _ => 'Unable to send password reset email. Please try again.',
      };
      emit(AuthFailure(msg));
    } catch (_) {
      emit(const AuthFailure('Failed to send password reset email. Please try again.'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

