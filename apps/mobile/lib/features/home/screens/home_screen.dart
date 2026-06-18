// ignore_for_file: public_member_api_docs

/// The foundation landing screen.
///
/// Demonstrates the FW-01 responsive primitives ([ResponsiveLayout]) and FW-03
/// routing (each button is a [GoRouter] navigation that changes the browser
/// URL). Real client/tasker home screens replace this in Sprint 2+.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_layout.dart';

/// Routes reachable from the foundation shell — kept in one place so the home
/// screen and the router stay in sync.
const List<({String label, String path})> kShellDestinations = [
  (label: 'Sign up', path: '/auth/signup'),
  (label: 'Post a job', path: '/post'),
  (label: 'Browse a job', path: '/jobs/demo'),
  (label: 'My profile', path: '/me'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => const _HomeBody(maxWidth: double.infinity),
          expanded: (context) => const Center(child: _HomeBody(maxWidth: 480)),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'JOBBees',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Foundation shell. Mobile and web from one codebase.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            for (final destination in kShellDestinations) ...[
              OutlinedButton(
                onPressed: () => context.go(destination.path),
                child: Text(destination.label),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
