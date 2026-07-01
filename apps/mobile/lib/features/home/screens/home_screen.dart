// ignore_for_file: public_member_api_docs

/// Home tab — the authenticated landing surface inside the bottom-nav shell.
///
/// Navigation now lives in the shell's [NavigationBar] + Post FAB (see
/// ScaffoldWithNavBar), so this is just the Home tab's content. The real
/// client/tasker feed (job discovery, activity) arrives in Sprint 3+; for now a
/// branded welcome so the tab has a home.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JOBBees')),
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
          children: [
            Icon(LucideIcons.house, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Welcome to JOBBees',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your jobs and activity will appear here.\nTap + to post a job.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
