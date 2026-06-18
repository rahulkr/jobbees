// ignore_for_file: public_member_api_docs

/// Transparently refreshes an expired session and replays the failed request
/// (ADR 006).
///
/// On a 401 from a protected endpoint it asks [refreshSession] (the single-
/// flight refresh owned by AuthController) for a fresh token, then retries the
/// original request exactly once — replayed through [dio] so the refreshed
/// Bearer (mobile) / cookie (web) is re-applied by the surface interceptor.
/// Auth endpoints are exempt so a failing refresh/login can't loop, and a
/// `QueuedInterceptor` serialises concurrent 401s onto that one refresh.
library;

import 'package:dio/dio.dart';

class AuthRefreshInterceptor extends QueuedInterceptor {
  AuthRefreshInterceptor({required this.dio, required this.refreshSession});

  final Dio dio;
  final Future<bool> Function() refreshSession;

  static const String _retriedFlag = 'auth_retried';

  /// Endpoints that must never trigger a refresh-and-retry (they ARE the auth
  /// flow). A 401 here is a genuine credential failure.
  static const Set<String> _exemptPaths = {
    '/auth/login',
    '/auth/signup',
    '/auth/refresh',
    '/auth/logout',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[_retriedFlag] != true &&
        !_exemptPaths.contains(request.path);

    if (!shouldRefresh) return handler.next(err);

    final refreshed = await refreshSession();
    if (!refreshed) return handler.next(err); // session cleared; surface 401

    try {
      request.extra[_retriedFlag] = true;
      return handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
