// ignore_for_file: public_member_api_docs

/// Enables cross-origin credentials on the dio browser adapter (FW-02).
///
/// Conditional export: on web this flips `withCredentials` so the API's
/// HttpOnly session cookies are sent cross-origin; elsewhere it is a no-op.
library;

export 'web_credentials_stub.dart'
    if (dart.library.js_interop) 'web_credentials_web.dart';
