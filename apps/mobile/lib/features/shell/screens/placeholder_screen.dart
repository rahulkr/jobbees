// ignore_for_file: public_member_api_docs

/// Foundation placeholder for routes whose real screens land in Sprint 2+.
///
/// It exists so [GoRouter] has something to render at each web URL today,
/// proving deep links + browser back/forward work end to end (FW-03). It also
/// surfaces the live [WindowSizeClass] so responsiveness is visible in Chrome.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/breakpoints.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.route,
    super.key,
  });

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(route, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Window: ${Breakpoints.of(context).name}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
