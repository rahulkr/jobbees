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
