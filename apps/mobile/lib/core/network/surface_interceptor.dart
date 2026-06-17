// ignore_for_file: public_member_api_docs

/// Applies ADR 006 per-surface authentication to every outgoing request
/// (FW-02).
///
/// - Web: relies on the API's HttpOnly `jb_access`/`jb_refresh` cookies (sent
///   automatically once `withCredentials` is enabled) and echoes the readable
///   `XSRF-TOKEN` cookie into `X-XSRF-TOKEN` on mutating requests
///   (double-submit CSRF).
/// - Mobile: attaches `Authorization: Bearer` from the in-memory token.
///
/// Either way it advertises the surface via `X-Surface`, the single header the
/// API switches on to choose cookie vs Bearer handling.
library;

import 'package:dio/dio.dart';

import '../platform/platform_info.dart';
import 'csrf_cookie_reader.dart';

class SurfaceInterceptor extends Interceptor {
  SurfaceInterceptor({required this.readAccessToken});

  /// Returns the current mobile access token (null on web / when signed out).
  final String? Function() readAccessToken;

  static const Set<String> _mutatingMethods = {
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Surface'] = PlatformInfo.surface;

    if (PlatformInfo.isWeb) {
      if (_mutatingMethods.contains(options.method.toUpperCase())) {
        final csrf = readCsrfToken();
        if (csrf != null) options.headers['X-XSRF-TOKEN'] = csrf;
      }
    } else {
      final token = readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
