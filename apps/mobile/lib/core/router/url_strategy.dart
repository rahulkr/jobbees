// ignore_for_file: public_member_api_docs

/// Selects the web URL strategy (FW-03).
///
/// Conditional export: on web this switches to clean path URLs; elsewhere it is
/// a no-op (the web-only `flutter_web_plugins` import must never load on
/// mobile).
library;

export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
