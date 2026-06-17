// ignore_for_file: public_member_api_docs

/// Web implementation: reads `XSRF-TOKEN` from `document.cookie`.
///
/// The API sets `XSRF-TOKEN` as a readable (non-HttpOnly) cookie precisely so
/// the SPA can echo it back in the `X-XSRF-TOKEN` header — the double-submit
/// half of CSRF protection. The session cookies (`jb_access`/`jb_refresh`) stay
/// HttpOnly and are never visible here.
library;

import 'package:web/web.dart' as web;

const String _csrfCookieName = 'XSRF-TOKEN';

String? readCsrfToken() {
  final raw = web.document.cookie;
  if (raw.isEmpty) return null;

  for (final pair in raw.split('; ')) {
    final separator = pair.indexOf('=');
    if (separator <= 0) continue;
    if (pair.substring(0, separator) == _csrfCookieName) {
      return Uri.decodeComponent(pair.substring(separator + 1));
    }
  }
  return null;
}
