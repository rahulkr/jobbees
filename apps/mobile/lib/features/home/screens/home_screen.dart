// ignore_for_file: public_member_api_docs

/// The foundation landing screen.
///
/// Demonstrates the FW-01 responsive primitives ([ResponsiveLayout]) and FW-03
/// routing (each button is a [GoRouter] navigation that changes the browser
/// URL). Real client/tasker home screens replace this in Sprint 2+.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_controller.dart';

typedef _Destination = ({String label, String path});

/// Shell entries shown to everyone (kept here so home + router stay in sync).
const List<({String label, String path})> kShellDestinations = [
  (label: 'Post a job', path: '/post'),
  (label: 'Browse a job', path: '/jobs/demo'),
];

/// Role-specific entries. A client can switch on the tasker side of their
/// account (they keep posting); a tasker manages verification + their profile.
/// Both reachable from one account, per the role model.
List<_Destination> _roleDestinations(UserRole? role) => role == UserRole.tasker
    ? const [
        (label: 'Verification', path: '/verify'),
        (label: 'My tasker profile', path: '/profile/tasker'),
      ]
    : const [(label: 'Work as a tasker', path: '/become-tasker')];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).valueOrNull?.role;
    final destinations = <_Destination>[
      ...kShellDestinations,
      ..._roleDestinations(role),
      (label: 'My profile', path: '/me'),
    ];
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) =>
              _HomeBody(maxWidth: double.infinity, destinations: destinations),
          expanded: (context) => Center(
            child: _HomeBody(maxWidth: 480, destinations: destinations),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.maxWidth, required this.destinations});

  final double maxWidth;
  final List<_Destination> destinations;

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
            for (final destination in destinations) ...[
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
