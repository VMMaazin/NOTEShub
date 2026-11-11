import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent {
  const AuthEvent();
}

/// Dispatched on app launch to begin listening to Firebase Auth state.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Dispatched whenever Firebase Auth emits a new [User].
class AuthUserChanged extends AuthEvent {
  final User? user;
  const AuthUserChanged(this.user);
}

/// Dispatched when an administrator submits credentials.
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });
}

/// Dispatched when an administrator signs out.
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Dispatched to trigger a password reset email.
class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);
}

