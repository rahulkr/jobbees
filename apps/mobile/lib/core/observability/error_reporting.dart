// ignore_for_file: public_member_api_docs

/// Crash + error reporting (Sentry).
///
/// The DSN is supplied at build time:
///   `flutter run --dart-define=SENTRY_DSN=https://...@oXXX.ingest.sentry.io/XXX`
/// When it's empty (the default — local dev, tests, no key yet) Sentry is NOT
/// initialised and [initErrorReporting] just runs the app: a clean no-op.
///
/// Config is conservative for cost + privacy (see the SENTRY decision):
///  - errors by default; a low, fixed traces sample so performance units don't
///    burn the free-tier quota;
///  - `sendDefaultPii = false` — the SDK never attaches IP, cookies, request
///    headers/body, or device PII (Australian Privacy Act). We also never push
///    user email/phone into Sentry scope, so events carry no PII;
///  - spike protection is enabled in the Sentry project (server-side) so a bad
///    release can't drain the monthly quota in one go.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// DSN injected via `--dart-define=SENTRY_DSN=...`. Empty → reporting disabled.
const String kSentryDsn = String.fromEnvironment('SENTRY_DSN');

/// True when a DSN is configured (Sentry will initialise).
bool get errorReportingEnabled => kSentryDsn.isNotEmpty;

/// Initialises Sentry (when a DSN is configured) and runs [appRunner] inside
/// its error zone — Flutter + Dart errors are captured automatically. With no
/// DSN it simply runs the app.
Future<void> initErrorReporting(FutureOr<void> Function() appRunner) async {
  if (!errorReportingEnabled) {
    await appRunner();
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = kSentryDsn;
    options.environment = kReleaseMode ? 'production' : 'development';
    // Low, fixed performance sampling keeps us inside the free-tier quota.
    options.tracesSampleRate = 0.1;
    // Never attach IP / cookies / request data / device PII.
    options.sendDefaultPii = false;
  }, appRunner: appRunner);
}
