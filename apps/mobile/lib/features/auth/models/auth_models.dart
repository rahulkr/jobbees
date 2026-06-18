// ignore_for_file: public_member_api_docs

/// Auth domain models with hand-written JSON — codegen is off (ADR 009).
library;

import 'package:flutter/foundation.dart';

/// Roles the API can return. Self-serve signup only ever creates [client] or
/// [tasker]; admin roles exist server-side but never sign in on mobile.
enum UserRole {
  client,
  tasker,
  admin,
  superAdmin,
  unknown;

  static UserRole fromJson(String? value) => switch (value) {
    'CLIENT' => client,
    'TASKER' => tasker,
    'ADMIN' => admin,
    'SUPER_ADMIN' => superAdmin,
    _ => unknown,
  };

  /// Wire value the API expects (null for [unknown] — never sent).
  String? toJson() => switch (this) {
    client => 'CLIENT',
    tasker => 'TASKER',
    admin => 'ADMIN',
    superAdmin => 'SUPER_ADMIN',
    unknown => null,
  };
}

/// Mobile session tokens (Bearer flow). Web uses HttpOnly cookies instead.
@immutable
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  final String accessToken;
  final String refreshToken;
}

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    role: UserRole.fromJson(json['role'] as String?),
    emailVerified: json['emailVerified'] as bool? ?? false,
    phoneVerified: json['phoneVerified'] as bool? ?? false,
  );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool emailVerified;
  final bool phoneVerified;

  String get fullName => '$firstName $lastName'.trim();
}
