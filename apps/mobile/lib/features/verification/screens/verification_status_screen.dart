// ignore_for_file: public_member_api_docs

/// Verification status (inventory row 25).
///
/// The tasker verification hub. For Sprint 2 it shows ABN status (none /
/// pending / verified); the Stripe Connect row joins here when Connect lands.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/abn_status.dart';
import '../providers/verification_providers.dart';

class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(abnStatusProvider);
    final phoneVerified =
        ref.watch(authControllerProvider).valueOrNull?.phoneVerified ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(
            context,
            ref,
            status,
            phoneVerified,
            maxWidth: double.infinity,
          ),
          expanded: (context) => Center(
            child: _body(context, ref, status, phoneVerified, maxWidth: 480),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AbnStatus> status,
    bool phoneVerified, {
    required double maxWidth,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: status.when(
          loading: () => const _VerificationSkeleton(),
          error: (_, _) =>
              _ErrorState(onRetry: () => ref.invalidate(abnStatusProvider)),
          data: (abn) => ListView(
            padding: const EdgeInsets.all(JSpacing.lg),
            children: [
              _AbnCard(status: abn),
              const SizedBox(height: JSpacing.base),
              _PhoneCard(verified: phoneVerified),
            ],
          ),
        ),
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
        ? (LucideIcons.badgeCheck, scheme.primary, 'Verified')
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
              onPressed: () => context.go('/verify/phone'),
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
        scheme.primary,
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
            onPressed: () => context.go('/verify/abn'),
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

/// Loading placeholder mirroring the two verification cards (ABN + phone).
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
      ],
    );
  }
}

/// A single ghost card: real card chrome (kept crisp, outside the shimmer) with
/// shimmering placeholder shapes inside, matching an [_AbnCard] / [_PhoneCard].
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: JSpacing.xxl),
          Icon(LucideIcons.cloudOff, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: JSpacing.base),
          Text(
            "Couldn't load your verification status.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: JSpacing.lg),
          JButton.secondary(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
