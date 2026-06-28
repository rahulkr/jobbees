// ignore_for_file: public_member_api_docs

/// Profile + account home (`/me`).
///
/// The signed-in account hub. Everyone signs up as a client (client note #4),
/// so this is where becoming a tasker lives — an in-app upgrade, not a choice
/// at signup. A client sees a "Become a tasker" card; a tasker sees their
/// verification + tasker-profile entries. It's one account either way: a tasker
/// still posts jobs as a client.
///
/// Four states (CLAUDE.md rule 3): only reachable while signed in, so content is
/// the norm; loading covers the startup restore probe and the signed-out branch
/// is a defensive fallback (the router would normally redirect first).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_controller.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _SignedOut(),
          data: (user) => user == null
              ? const _SignedOut()
              : ResponsiveLayout(
                  compact: (context) =>
                      _Body(user: user, maxWidth: double.infinity),
                  expanded: (context) =>
                      Center(child: _Body(user: user, maxWidth: 480)),
                ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.user, required this.maxWidth});

  final UserProfile user;
  final double maxWidth;

  bool get _isTasker => user.role == UserRole.tasker;

  Future<void> _logout(WidgetRef ref) =>
      ref.read(authControllerProvider.notifier).logout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(user: user),
              const SizedBox(height: JSpacing.xl),
              if (_isTasker)
                ..._taskerEntries(context)
              else
                _BecomeTaskerCard(onTap: () => context.go('/become-tasker')),
              const SizedBox(height: JSpacing.xl),
              JButton.danger(
                label: 'Log out',
                icon: LucideIcons.logOut,
                onPressed: () => _logout(ref),
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _taskerEntries(BuildContext context) => [
    _NavRow(
      icon: LucideIcons.badgeCheck,
      title: 'Verification',
      subtitle: 'ABN, payouts and phone.',
      onTap: () => context.go('/verify'),
    ),
    const SizedBox(height: JSpacing.base),
    _NavRow(
      icon: LucideIcons.user,
      title: 'My tasker profile',
      subtitle: 'Bio, hourly rate and skills.',
      onTap: () => context.go('/profile/tasker'),
    ),
  ];
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final UserProfile user;

  String get _initials {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$first$last'.trim();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: JSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName.isEmpty ? 'Your account' : user.fullName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: JSpacing.xs),
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The client-side upgrade prompt — the home of "become a tasker" now that it's
/// off the signup funnel.
class _BecomeTaskerCard extends StatelessWidget {
  const _BecomeTaskerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return JCard.tappable(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(
              LucideIcons.briefcase,
              size: 24,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: JSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a tasker',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: JSpacing.xs),
                Text(
                  'Find work and get paid. You keep your account and can '
                  'still post jobs.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: JSpacing.sm),
          Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return JCard.tappable(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(icon, size: 22, color: scheme.primary),
          ),
          const SizedBox(width: JSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: JSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: JSpacing.sm),
          Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(JSpacing.lg),
        child: Text('Sign in to view your profile.'),
      ),
    );
  }
}
