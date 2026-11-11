import '../../../core/models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

/// Initializing authentication.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Processing authentication transaction.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Student or Guest state: Unauthenticated, but granted complete read-only access.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authenticated user: role resolved from `users/{uid}` in Firestore.
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);

  bool get isAuthor => user.isAuthor;
  bool get isOwner => user.isOwner;
}

/// An authentication error occurred.
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}

/// Password reset email dispatched successfully.
class PasswordResetSent extends AuthState {
  final String email;
  const PasswordResetSent(this.email);
}

