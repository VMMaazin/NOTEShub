import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile in the `users` Firestore collection.
///
/// SECURITY NOTE:
/// Role resolution is performed via Firestore document reads at `users/{uid}`.
/// The [ownerUid] constant exists solely as a client-side bootstrap mechanism for
/// initial developer/owner configuration and does NOT replace server-side
/// authorization. True write authorization must be enforced via Firestore Security
/// Rules or Firebase Admin SDK.
class UserModel {
  final String uid;
  final String? role; // 'owner' | 'author' | null (student/guest)
  final String? name;

  const UserModel({
    required this.uid,
    this.role,
    this.name,
  });

  /// Client bootstrap UID for the platform owner.
  /// LIMITATION: This client check only gates UI visibility. The backend Firestore
  /// Security Rules must independently verify UID or custom claims for database mutations.
  static const String ownerUid = 'U8YkrUlxR9OLwB2XPiwi8AiOo372';

  /// Student or guest role when no administrative role exists.
  bool get isStudent => !isAuthor;

  /// Whether the user has author privileges.
  bool get isAuthor => role == 'author' || isOwner;

  /// Whether the user has owner privileges.
  bool get isOwner => role == 'owner' || uid == ownerUid;

  /// Serializes from Firestore snapshot.
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return UserModel(
      uid: snapshot.id,
      role: data?['role'] as String?,
      name: data?['name'] as String?,
    );
  }

  /// Deserializes from Map representation.
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      role: data['role'] as String?,
      name: data['name'] as String?,
    );
  }

  /// Serializes to Firestore document map.
  Map<String, dynamic> toFirestore() {
    return {
      if (role != null) 'role': role,
      if (name != null) 'name': name,
    };
  }

  UserModel copyWith({
    String? uid,
    String? role,
    String? name,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          role == other.role &&
          name == other.name;

  @override
  int get hashCode => uid.hashCode ^ (role?.hashCode ?? 0) ^ (name?.hashCode ?? 0);

  @override
  String toString() => 'UserModel(uid: $uid, role: $role, name: $name, isAuthor: $isAuthor)';
}
