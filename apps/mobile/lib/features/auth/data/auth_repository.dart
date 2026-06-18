// ignore_for_file: public_member_api_docs

/// Thin wrapper over the API's `/auth` endpoints (apps/mobile CLAUDE.md rule 2 —
/// screens never call dio directly).
///
/// Per-surface auth (Bearer vs cookie) and the `X-Surface` header are applied by
/// [SurfaceInterceptor]; this layer just shapes requests, attaches the required
/// `Idempotency-Key` on mutating calls, and parses responses. On mobile, signup
/// returns a [TokenPair]; on web the API sets HttpOnly cookies and returns
/// `{ csrfToken }`, so the token pair is null there.
library;

import 'package:dio/dio.dart';

import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio, {required this.newIdempotencyKey});

  final Dio _dio;
  final String Function() newIdempotencyKey;

  Future<TokenPair?> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (role?.toJson() case final r?) 'role': r,
      },
      options: _idempotent(),
    );
    return _tokensOrNull(res.data);
  }

  Future<UserProfile> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserProfile.fromJson(res.data!);
  }

  Future<TokenPair?> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: _idempotent(),
    );
    return _tokensOrNull(res.data);
  }

  /// Signs in with a verified provider ID token (provider = google | apple).
  /// First-time tokens create the account; [firstName]/[lastName] seed the
  /// profile (Apple only sends the name on first auth). Returns a [TokenPair]
  /// on mobile; null on web (cookie session).
  Future<TokenPair?> oauthLogin({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
    UserRole? role,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: {
        'idToken': idToken,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (role?.toJson() case final r?) 'role': r,
      },
      options: _idempotent(),
    );
    return _tokensOrNull(res.data);
  }

  /// Exchanges a refresh token for a fresh pair. Mobile passes [refreshToken];
  /// web sends nothing (the API reads its HttpOnly `jb_refresh` cookie) and the
  /// returned pair is null because new tokens come back as cookies.
  Future<TokenPair?> refresh(String? refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {if (refreshToken != null) 'refreshToken': refreshToken},
      options: _idempotent(),
    );
    return _tokensOrNull(res.data);
  }

  /// Verifies an email address with the token from the verification email.
  Future<void> verifyEmail(String token) async {
    await _dio.post<void>(
      '/auth/email/verify',
      data: {'token': token},
      options: _idempotent(),
    );
  }

  /// Resends the verification email to the signed-in user (Bearer required).
  Future<void> resendVerificationEmail() async {
    await _dio.post<void>('/auth/email/resend', options: _idempotent());
  }

  /// Requests a password-reset email. The API always succeeds (it never reveals
  /// whether the email exists), so there's nothing to return.
  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/auth/password/forgot',
      data: {'email': email},
      options: _idempotent(),
    );
  }

  /// Sets a new password using the token from the reset email.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/password/reset',
      data: {'token': token, 'newPassword': newPassword},
      options: _idempotent(),
    );
  }

  /// Upgrades the current client account to a tasker (one-way). The caller must
  /// refresh the session afterwards so the new role lands in the access token.
  Future<void> becomeTasker() async {
    await _dio.post<void>('/me/become-tasker', options: _idempotent());
  }

  Future<void> logout(String? refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {if (refreshToken != null) 'refreshToken': refreshToken},
      options: _idempotent(),
    );
  }

  Options _idempotent() =>
      Options(headers: {'Idempotency-Key': newIdempotencyKey()});

  TokenPair? _tokensOrNull(Map<String, dynamic>? data) {
    if (data != null && data['accessToken'] != null) {
      return TokenPair.fromJson(data);
    }
    return null; // web: cookie session, body is { csrfToken }
  }
}
