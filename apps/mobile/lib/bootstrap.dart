// ignore_for_file: public_member_api_docs

/// App entry plumbing shared by `main.dart` (and, later, flavored entrypoints).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/analytics.dart';
import 'core/network/api_client.dart';
import 'core/observability/error_reporting.dart';
import 'core/router/url_strategy.dart';
import 'features/auth/providers/auth_controller.dart';
import 'features/onboarding/providers/onboarding_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inter is bundled in assets/google_fonts/, so never fetch it over the network
  // — faster cold start, works offline, and a missing weight fails loudly in dev
  // instead of silently degrading. See pubspec.yaml assets.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Web: serve clean `/jobs/123` URLs instead of `/#/jobs/123`, so deep links
  // and browser history match the API + Next.js surfaces (FW-03). No-op on
  // mobile.
  configureUrlStrategy();

  // Resolved synchronously before the first frame so onboarding state (the
  // welcome-carousel "seen" flag) is available to the router's first redirect
  // — no async splash flicker waiting on disk.
  final prefs = await SharedPreferences.getInstance();

  // Product analytics (no-op until POSTHOG_KEY is set).
  await Analytics.init();

  // Runs the app inside Sentry's error zone when a DSN is configured; a plain
  // runApp otherwise (no-op until SENTRY_DSN is set).
  await initErrorReporting(() {
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Let the network layer's 401-retry delegate to AuthController without
          // `core` importing the auth feature (composition wired here).
          sessionRefresherProvider.overrideWith(
            (ref) =>
                () =>
                    ref.read(authControllerProvider.notifier).refreshSession(),
          ),
        ],
        child: const JobbeesApp(),
      ),
    );
  });
}
