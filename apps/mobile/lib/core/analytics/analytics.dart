// ignore_for_file: public_member_api_docs

/// Product analytics (PostHog) — the funnel layer, distinct from Sentry (errors).
///
/// Opt-in via build-time keys:
///   `flutter run --dart-define=POSTHOG_KEY=phc_xxx --dart-define=POSTHOG_HOST=https://eu.i.posthog.com`
/// With no key (local dev, tests, not configured yet) every call is a no-op, so
/// nothing is sent and nothing breaks.
///
/// Privacy (Australian Privacy Act): we identify users by their opaque cuid id
/// only — never email/phone — and event properties carry no PII. Session replay
/// / autocapture of inputs are left off (PostHog defaults).
library;

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Project API key, injected via `--dart-define=POSTHOG_KEY=...`. Empty → off.
const String kPostHogKey = String.fromEnvironment('POSTHOG_KEY');

/// PostHog ingest host — pick the region the project was created in. Defaults to
/// EU (closer to AU data-residency expectations than US).
const String kPostHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://eu.i.posthog.com',
);

/// Thin wrapper so screens/controllers call one stable API and analytics can
/// never throw into app flow.
class Analytics {
  const Analytics._();

  static bool get enabled => kPostHogKey.isNotEmpty;

  static Future<void> init() async {
    if (!enabled) return;
    await _guard(() async {
      final config = PostHogConfig(kPostHogKey)..host = kPostHogHost;
      await Posthog().setup(config);
    });
  }

  /// Records an event. [properties] must be PII-free.
  static Future<void> track(String event, [Map<String, Object>? properties]) {
    if (!enabled) return Future.value();
    return _guard(
      () => Posthog().capture(eventName: event, properties: properties),
    );
  }

  /// Associates subsequent events with [userId] (an opaque cuid — never PII).
  static Future<void> identify(String userId) {
    if (!enabled) return Future.value();
    return _guard(() => Posthog().identify(userId: userId));
  }

  /// Clears the identity on sign-out.
  static Future<void> reset() {
    if (!enabled) return Future.value();
    return _guard(() => Posthog().reset());
  }

  // Analytics is non-critical: a failure here must never surface to the user.
  static Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (error) {
      if (kDebugMode) debugPrint('Analytics error (ignored): $error');
    }
  }
}
