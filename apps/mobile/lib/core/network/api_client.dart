// ignore_for_file: public_member_api_docs

/// The app-wide configured [Dio] (FW-02).
///
/// Per-surface auth (ADR 006) is applied by [SurfaceInterceptor]; on web,
/// browser credentials are enabled so the API's HttpOnly session cookies ride
/// along cross-origin.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_token.dart';
import 'auth_refresh_interceptor.dart';
import 'surface_interceptor.dart';
import 'web_credentials.dart';

/// Base URL of the JOBBees API. Override at build time with
/// `--dart-define=API_BASE_URL=https://...`; defaults to local dev.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

/// Refreshes the session on a 401 and reports whether a fresh token is now in
/// place. Defaults to "cannot refresh"; the auth layer overrides this in
/// `bootstrap()` to delegate to AuthController, keeping `core` free of a
/// feature dependency.
final sessionRefresherProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );

  enableWebCredentials(dio);
  dio.interceptors.add(
    SurfaceInterceptor(readAccessToken: () => ref.read(accessTokenProvider)),
  );
  dio.interceptors.add(
    AuthRefreshInterceptor(
      dio: dio,
      refreshSession: () => ref.read(sessionRefresherProvider)(),
    ),
  );

  return dio;
});
