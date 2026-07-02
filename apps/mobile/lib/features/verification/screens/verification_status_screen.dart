// ignore_for_file: public_member_api_docs

/// Verification status (inventory row 25).
///
/// The tasker verification hub: Stripe Connect payout setup (row 44), ABN status
/// (none / pending / verified), and phone verification. Refreshes the Connect
/// status when the tasker returns from the Stripe-hosted onboarding browser.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbees_mobile/theme/colors.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/abn_status.dart';
import '../models/connect_status.dart';
import '../providers/connect_providers.dart';
import '../providers/verification_providers.dart';

class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from the Stripe-hosted onboarding browser fires a resume.
    // Re-fetch Connect status so a just-completed onboarding flips the card —
    // but stop once payouts are live, so we don't poll needlessly.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final current = ref.read(connectStatusProvider).valueOrNull;
        if (current == null || current.needsSetup) {
          ref.read(connectStatusProvider.notifier).refresh();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abn = ref.watch(abnStatusProvider);
    final connect = ref.watch(connectStatusProvider);
    final phoneVerified =
        ref.watch(authControllerProvider).valueOrNull?.phoneVerified ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) =>
              _body(abn, connect, phoneVerified, maxWidth: double.infinity),
          expanded: (context) =>
              Center(child: _body(abn, connect, phoneVerified, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(
    AsyncValue<AbnStatus> abn,
    AsyncValue<ConnectStatus> connect,
    bool phoneVerified, {
    required double maxWidth,
  }) {
    final Widget child;
    if (abn.isLoading || connect.isLoading) {
      child = const _VerificationSkeleton();
    } else if (abn.hasError || connect.hasError) {
      child = _ErrorState(
        onRetry: () {
          ref.invalidate(abnStatusProvider);
          ref.invalidate(connectStatusProvider);
        },
      );
    } else {
      child = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(abnStatusProvider);
          await ref.read(connectStatusProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(JSpacing.lg),
          children: [
            JEntrance(child: _ConnectCard(status: connect.requireValue)),
            const SizedBox(height: JSpacing.base),
            JEntrance(
              delay: const Duration(milliseconds: 80),
              child: _AbnCard(status: abn.requireValue),
            ),
            const SizedBox(height: JSpacing.base),
            JEntrance(
              delay: const Duration(milliseconds: 160),
              child: _PhoneCard(verified: phoneVerified),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Stripe Connect payout onboarding (rows 44 + 25). Tapping the action fetches a
/// fresh Stripe account link and opens it in the system browser; the hub
/// refreshes the status on return.
class _ConnectCard extends ConsumerStatefulWidget {
  const _ConnectCard({required this.status});

  final ConnectStatus status;

  @override
  ConsumerState<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends ConsumerState<_ConnectCard> {
  bool _launching = false;

  Future<void> _start() async {
    setState(() => _launching = true);
    try {
      await ref.read(connectStatusProvider.notifier).beginOnboarding();
    } on AppError catch (error) {
      if (mounted) JSnackbar.showError(context, error.message);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = widget.status;

    final (IconData icon, Color tint, String label) = switch (status) {
      final s when s.isComplete => (
        LucideIcons.badgeCheck,
        JobbeesColors.success,
        'Active',
      ),
      final s when s.isPending => (
        LucideIcons.hourglass,
        scheme.tertiary,
        'In progress',
      ),
      final s when s.isRestricted => (
        LucideIcons.triangleAlert,
        scheme.error,
        'Action needed',
      ),
      _ => (LucideIcons.wallet, scheme.onSurfaceVariant, 'Not set up'),
    };

    final String body = switch (status) {
      final s when s.isComplete =>
        "You're all set to receive payouts for completed jobs.",
      final s when s.isPending =>
        'Finish your payout setup with Stripe so you can get paid.',
      final s when s.isRestricted =>
        'Stripe needs a bit more information before payouts can be enabled.',
      _ =>
        'Set up payouts with Stripe so you can get paid for the jobs you '
            'complete.',
    };

    final String? actionLabel = status.isComplete
        ? null
        : (status.isNotStarted ? 'Set up payouts' : 'Continue setup');

    return JCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint),
              const SizedBox(width: JSpacing.sm),
              Expanded(
                child: Text(
                  'Payouts',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(label: label, tint: tint),
            ],
          ),
          const SizedBox(height: JSpacing.base),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: JSpacing.base),
            JButton.secondary(
              label: _launching ? 'Opening Stripe…' : actionLabel,
              onPressed: _launching ? null : _start,
              loading: _launching,
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, Color tint, String label) = verified
        ? (LucideIcons.badgeCheck, JobbeesColors.success, 'Verified')
        : (LucideIcons.smartphone, scheme.onSurfaceVariant, 'Not verified');

    return JCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint),
              const SizedBox(width: JSpacing.sm),
              Expanded(
                child: Text(
                  'Phone',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(label: label, tint: tint),
            ],
          ),
          const SizedBox(height: JSpacing.base),
          Text(
            verified
                ? 'Your phone number is verified.'
                : 'Verify your phone number to keep your account secure.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (!verified) ...[
            const SizedBox(height: JSpacing.base),
            JButton.secondary(
              label: 'Verify phone',
              onPressed: () => context.push('/verify/phone'),
              expanded: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _AbnCard extends StatelessWidget {
  const _AbnCard({required this.status});

  final AbnStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, Color tint, String label) = switch (status) {
      final s when s.isVerified => (
        LucideIcons.badgeCheck,
        JobbeesColors.success,
        'Verified',
      ),
      final s when s.isPending => (
        LucideIcons.hourglass,
        scheme.tertiary,
        'Pending',
      ),
      _ => (LucideIcons.building2, scheme.onSurfaceVariant, 'Not added'),
    };

    return JCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint),
              const SizedBox(width: JSpacing.sm),
              Expanded(
                child: Text(
                  'ABN',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(label: label, tint: tint),
            ],
          ),
          const SizedBox(height: JSpacing.base),
          if (status.isEmpty)
            Text(
              'Add your ABN so clients can see your registered business.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (status.businessName != null)
              Text(status.businessName!, style: textTheme.bodyLarge),
            const SizedBox(height: JSpacing.xs),
            Text(
              _formatAbn(status.abn!),
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (status.isPending) ...[
              const SizedBox(height: JSpacing.sm),
              Text(
                "We couldn't confirm this ABN yet. It can take a moment, or you "
                'can re-enter it.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: JSpacing.base),
          JButton.secondary(
            label: status.isEmpty ? 'Add ABN' : 'Update ABN',
            onPressed: () => context.push('/verify/abn'),
            expanded: true,
          ),
        ],
      ),
    );
  }

  /// 11 digits → "XX XXX XXX XXX" for display.
  String _formatAbn(String abn) {
    if (abn.length != 11) return abn;
    return '${abn.substring(0, 2)} ${abn.substring(2, 5)} '
        '${abn.substring(5, 8)} ${abn.substring(8, 11)}';
  }
}

/// Loading placeholder mirroring the three verification cards.
/// A skeleton in the content's shape, not a spinner (UI-PRINCIPLES § Loading).
class _VerificationSkeleton extends StatelessWidget {
  const _VerificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(JSpacing.lg),
      children: const [
        _GhostCard(),
        SizedBox(height: JSpacing.base),
        _GhostCard(),
        SizedBox(height: JSpacing.base),
        _GhostCard(),
      ],
    );
  }
}

/// A single ghost card: real card chrome (kept crisp, outside the shimmer) with
/// shimmering placeholder shapes inside, matching a real verification card.
class _GhostCard extends StatelessWidget {
  const _GhostCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: JRadius.cardAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(JSpacing.base),
      child: const JShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JSkeleton.circle(size: 24),
                SizedBox(width: JSpacing.sm),
                JSkeleton.line(width: 64),
                Spacer(),
                JSkeleton.box(width: 72, height: 24, radius: JRadius.chipAll),
              ],
            ),
            SizedBox(height: JSpacing.base),
            JSkeleton.line(),
            SizedBox(height: JSpacing.sm),
            JSkeleton.line(width: 200),
            SizedBox(height: JSpacing.base),
            JSkeleton.box(height: 52),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: JSpacing.md,
        vertical: JSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: JRadius.chipAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w600,
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
    // Full-screen designed error state per Design Quality Charter § criterion 7
    // (no red-text-only errors).
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: JEmptyState(
        icon: LucideIcons.cloudOff,
        title: "We couldn't load your verification status",
        body:
            "Give it another go. If it keeps happening, tap Support and "
            "we'll take a look.",
        primaryAction: JButton.primary(label: 'Try again', onPressed: onRetry),
      ),
    );
  }
}
