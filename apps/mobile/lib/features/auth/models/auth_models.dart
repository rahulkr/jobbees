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

/// Account standing as the client cares about it. The API only blocks a
/// [suspended] account at login (it never ships suspension in `/me`), so mobile
/// carries it as session state and the router routes to the account-suspended
/// screen (CLAUDE.md rule 5).
enum AccountStatus { active, suspended }

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
    this.status = AccountStatus.active,
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

  /// A minimal sentinel for a suspended session. Built from the login error
  /// (not `/me`, which is never reached when login is blocked): only [email]
  /// and [status] are meaningful — the rest are placeholders so the router can
  /// treat it as a non-null, suspended session.
  factory UserProfile.suspended({String email = ''}) => UserProfile(
    id: '',
    email: email,
    firstName: '',
    lastName: '',
    role: UserRole.unknown,
    emailVerified: false,
    phoneVerified: false,
    status: AccountStatus.suspended,
  );

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool emailVerified;
  final bool phoneVerified;
  final AccountStatus status;

  bool get isSuspended => status == AccountStatus.suspended;

  String get fullName => '$firstName $lastName'.trim();
}
