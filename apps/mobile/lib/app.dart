// ignore_for_file: public_member_api_docs

/// Root application widget: `MaterialApp.router` wired to the brand theme and
/// the go_router config.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'theme/app_theme.dart';

class JobbeesApp extends ConsumerWidget {
  const JobbeesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'JOBBees',
      debugShowCheckedModeBanner: false,
      theme: JobbeesTheme.light(),
      darkTheme: JobbeesTheme.dark(),
      routerConfig: router,
    );
  }
}
