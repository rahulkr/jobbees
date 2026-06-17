// ignore_for_file: public_member_api_docs

/// Web-safe platform queries (FW-01).
///
/// `dart:io`'s `Platform.is*` throws on web, so adaptive code must never call
/// it directly. These helpers are [kIsWeb]-guarded and drive both adaptive
/// (Material vs Cupertino) selection and the per-surface auth dispatch.
library;

import 'package:flutter/foundation.dart';

class PlatformInfo {
  PlatformInfo._();

  /// True when running as Flutter Web (desktop or mobile browser).
  static bool get isWeb => kIsWeb;

  /// True on iOS/macOS — used to opt into Cupertino-style adaptive widgets.
  /// Always false on web; browsers get the Material look for parity with the
  /// Next.js admin + web surfaces.
  static bool get isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// The value sent in the `X-Surface` header so the API can pick cookie vs
  /// Bearer auth (ADR 006). Only `web` is load-bearing server-side; the mobile
  /// values are informational.
  static String get surface {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'mobile';
    }
  }
}
