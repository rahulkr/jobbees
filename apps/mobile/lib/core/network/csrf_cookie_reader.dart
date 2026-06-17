// ignore_for_file: public_member_api_docs

/// Reads the non-HttpOnly `XSRF-TOKEN` cookie for double-submit CSRF (FW-02).
///
/// Conditional export: a real `document.cookie` reader on web, a no-op stub
/// everywhere else (mobile uses Bearer auth and never touches cookies).
library;

export 'csrf_cookie_reader_stub.dart'
    if (dart.library.js_interop) 'csrf_cookie_reader_web.dart';
