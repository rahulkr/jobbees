// ignore_for_file: public_member_api_docs

/// App entry plumbing shared by `main.dart` (and, later, flavored entrypoints).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/router/url_strategy.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: serve clean `/jobs/123` URLs instead of `/#/jobs/123`, so deep links
  // and browser history match the API + Next.js surfaces (FW-03). No-op on
  // mobile.
  configureUrlStrategy();

  runApp(const ProviderScope(child: JobbeesApp()));
}
