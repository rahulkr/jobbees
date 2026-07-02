// ignore_for_file: public_member_api_docs

/// Foundation placeholder for internal routes whose real screens land in a later
/// sprint (the create-a-job flow, job detail). It gives [GoRouter] something to
/// render so deep links + browser back/forward work end to end (FW-03).
///
/// NOT used on live bottom-nav tabs — Offers/Messages get a designed
/// [ComingSoonScreen] instead, so users never see this dev scaffold.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/ui.dart';

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
            const SizedBox(height: JSpacing.lg),
            JButton.primary(
              label: 'Back to home',
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
