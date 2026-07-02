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

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/providers/biometric_providers.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: const JAppBar(title: 'Profile'),
      body: SafeArea(
        child: session.when(
          // Skeleton, not a spinner, in a profile context (Charter § 5).
          loading: () => const _ProfileSkeleton(),
          // A restore/network error isn't "signed out" — name it and offer a
          // retry (Charter § 7). Genuine sign-out is the data(null) branch.
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
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
              JEntrance(child: _Header(user: user)),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 90),
                child: _isTasker
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _taskerEntries(context),
                      )
                    : _BecomeTaskerCard(
                        onTap: () => context.push('/become-tasker'),
                      ),
              ),
              const SizedBox(height: JSpacing.xl),
              // Biometric unlock — only when the device actually supports it
              // (hidden on web / unenrolled devices).
              if (ref.watch(biometricAvailableProvider).valueOrNull ??
                  false) ...[
                JEntrance(
                  delay: const Duration(milliseconds: 160),
                  child: const _BiometricToggleTile(),
                ),
                const SizedBox(height: JSpacing.xl),
              ],
              JEntrance(
                delay: const Duration(milliseconds: 240),
                child: JButton.danger(
                  label: 'Log out',
                  icon: LucideIcons.logOut,
                  onPressed: () => _logout(ref),
                  expanded: true,
                ),
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
      onTap: () => context.push('/verify'),
    ),
    const SizedBox(height: JSpacing.base),
    _NavRow(
      icon: LucideIcons.user,
      title: 'My tasker profile',
      subtitle: 'Bio, hourly rate and skills.',
      onTap: () => context.push('/profile/tasker'),
    ),
    const SizedBox(height: JSpacing.base),
    const _SwitchToClientTile(),
  ];
}

/// Lets a tasker switch back to a client (the reverse of "Become a tasker").
/// Reversible and non-destructive — tasker verification is kept — so a light
/// confirm is enough. On success the session flips to CLIENT and this screen
/// re-renders as the client view; failures surface in a snackbar.
class _SwitchToClientTile extends ConsumerStatefulWidget {
  const _SwitchToClientTile();

  @override
  ConsumerState<_SwitchToClientTile> createState() =>
      _SwitchToClientTileState();
}

class _SwitchToClientTileState extends ConsumerState<_SwitchToClientTile> {
  bool _submitting = false;

  Future<void> _confirmAndSwitch() async {
    if (_submitting) return;
    // Bottom sheet instead of AlertDialog — Charter § Bottom-sheet-first, and
    // VOICE § Conversational confirmations (button restates the action).
    final confirmed = await JBottomSheet.show<bool>(
      context: context,
      title: 'Switch to client?',
      child: const Text(
        'You will go back to hiring only. We keep your tasker details '
        '(ABN, payments and profile), so you can switch back anytime.',
        style: TextStyle(fontSize: 14),
      ),
      // The sheet is shown on the root navigator (so it covers the nav bar), so
      // pop the root navigator to close it.
      primaryAction: JButton.primary(
        label: 'Yes, switch to client',
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        expanded: true,
      ),
      secondaryAction: JButton.secondary(
        label: 'Keep both',
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        expanded: true,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).switchToClient();
      // Auth state flips to CLIENT; the profile re-renders as the client view.
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        JSnackbar.showError(
          context,
          error.message,
          onRetry: error.retryable ? _confirmAndSwitch : null,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return JCard.tappable(
      onTap: _confirmAndSwitch,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(
              LucideIcons.arrowLeftRight,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: JSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch to client',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: JSpacing.xs),
                Text(
                  'Go back to hiring only. Your tasker details are saved.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: JSpacing.sm),
          SizedBox(
            width: 24,
            height: 24,
            child: _submitting
                ? const Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    LucideIcons.chevronRight,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Toggles biometric unlock (Face ID / Touch ID / fingerprint). Turning it ON
/// first verifies with a biometric prompt so we never enable a lock the user
/// can't open; the flag persists on-device (see [biometricEnabledProvider]).
class _BiometricToggleTile extends ConsumerStatefulWidget {
  const _BiometricToggleTile();

  @override
  ConsumerState<_BiometricToggleTile> createState() =>
      _BiometricToggleTileState();
}

class _BiometricToggleTileState extends ConsumerState<_BiometricToggleTile> {
  bool _busy = false;

  Future<void> _set({required bool enabled}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (enabled) {
        final ok = await ref
            .read(biometricAuthServiceProvider)
            .authenticate(reason: 'Confirm to turn on biometric unlock');
        if (!ok) {
          if (mounted) {
            JHaptics.error();
            JSnackbar.showError(context, 'Could not verify your biometrics.');
          }
          return; // leave the switch off
        }
      }
      await ref.read(biometricEnabledProvider.notifier).set(enabled: enabled);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = ref.watch(biometricEnabledProvider);
    return JCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(
              LucideIcons.fingerprint,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: JSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric unlock',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: JSpacing.xs),
                Text(
                  'Use Face ID or your fingerprint to unlock the app.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: JSpacing.sm),
          if (_busy)
            const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch(
              value: enabled,
              onChanged: (value) => _set(enabled: value),
            ),
        ],
      ),
    );
  }
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
              color: scheme.surfaceContainerHighest,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(icon, size: 22, color: scheme.onSurfaceVariant),
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

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(JSpacing.lg),
      child: JShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JSkeleton.circle(size: 64),
                SizedBox(width: JSpacing.base),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JSkeleton.line(width: 160, height: 20),
                    SizedBox(height: JSpacing.sm),
                    JSkeleton.line(width: 200),
                  ],
                ),
              ],
            ),
            SizedBox(height: JSpacing.xl),
            JSkeleton.box(height: 88, radius: JRadius.cardAll),
            SizedBox(height: JSpacing.lg),
            JSkeleton.box(height: 88, radius: JRadius.cardAll),
            SizedBox(height: JSpacing.xl),
            JSkeleton.box(height: 56, radius: JRadius.buttonLgAll),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: JEmptyState(
        icon: LucideIcons.cloudOff,
        title: "We couldn't load your account",
        body:
            'Check your connection and give it another go. If it keeps '
            "happening, tap Support and we'll take a look.",
        primaryAction: JButton.primary(label: 'Try again', onPressed: onRetry),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(JSpacing.lg),
      child: JEmptyState(
        icon: LucideIcons.userRoundX,
        title: "You're signed out",
        body: 'Sign in to see your account details, verification and settings.',
      ),
    );
  }
}
