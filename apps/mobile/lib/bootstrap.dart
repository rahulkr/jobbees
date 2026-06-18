// ignore_for_file: public_member_api_docs

/// App entry plumbing shared by `main.dart` (and, later, flavored entrypoints).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/router/url_strategy.dart';
import 'features/onboarding/providers/onboarding_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: serve clean `/jobs/123` URLs instead of `/#/jobs/123`, so deep links
  // and browser history match the API + Next.js surfaces (FW-03). No-op on
  // mobile.
  configureUrlStrategy();

  // Resolved synchronously before the first frame so onboarding state (the
  // welcome-carousel "seen" flag) is available to the router's first redirect
  // — no async splash flicker waiting on disk.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const JobbeesApp(),
    ),
  );
}
