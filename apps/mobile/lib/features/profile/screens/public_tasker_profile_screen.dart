// ignore_for_file: public_member_api_docs

/// Public tasker profile (inventory row 47) — what a client sees: name, trust
/// badges, bio, hourly rate, skills. Reviews show a designed empty state until
/// S7 ships them.
///
/// Read-only; loads via [publicTaskerProfileProvider]. Four-state aware.
///
/// Design (per Design Quality Charter § Profile (other user) — Airbnb host bar):
///   * Avatar + name as hero, badges as secondary, hourly rate as anchor,
///     bio + skills as sections, reviews as designed empty state.
///   * Staggered entrance across sections so the data-loaded state unfolds.
///   * Error state uses JEmptyState so it feels like a screen, not a snackbar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../models/public_tasker_profile.dart';
import '../providers/profile_providers.dart';

class PublicTaskerProfileScreen extends ConsumerWidget {
  const PublicTaskerProfileScreen({required this.taskerId, super.key});

  final String taskerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicTaskerProfileProvider(taskerId));
    return Scaffold(
      appBar: const JAppBar(title: 'Tasker profile'),
      body: SafeArea(
        child: profile.when(
          loading: () => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const _ProfileSkeleton(),
            ),
          ),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.invalidate(publicTaskerProfileProvider(taskerId)),
          ),
          data: (data) => ResponsiveLayout(
            compact: (context) =>
                _body(context, data, maxWidth: double.infinity),
            expanded: (context) =>
                Center(child: _body(context, data, maxWidth: 480)),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    PublicTaskerProfile p, {
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: const EdgeInsets.all(JSpacing.lg),
          children: [
            JEntrance(
              child: Row(
                children: [
                  _Avatar(name: p.firstName),
                  const SizedBox(width: JSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.firstName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (p.businessName != null) ...[
                          const SizedBox(height: JSpacing.xs),
                          Text(
                            p.businessName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: JSpacing.base),
            JEntrance(
              delay: const Duration(milliseconds: 90),
              child: _Badges(badges: p.badges),
            ),
            if (p.hourlyRateCents != null) ...[
              const SizedBox(height: JSpacing.lg),
              JEntrance(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  '\$${(p.hourlyRateCents! / 100).toStringAsFixed(p.hourlyRateCents! % 100 == 0 ? 0 : 2)}/hr',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (p.bio != null && p.bio!.isNotEmpty) ...[
              const SizedBox(height: JSpacing.lg),
              JEntrance(
                delay: const Duration(milliseconds: 220),
                child: const _SectionTitle('About'),
              ),
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                delay: const Duration(milliseconds: 260),
                child: Text(p.bio!, style: theme.textTheme.bodyLarge),
              ),
            ],
            if (p.skills.isNotEmpty) ...[
              const SizedBox(height: JSpacing.lg),
              JEntrance(
                delay: const Duration(milliseconds: 300),
                child: const _SectionTitle('Skills'),
              ),
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                delay: const Duration(milliseconds: 340),
                child: Wrap(
                  spacing: JSpacing.sm,
                  runSpacing: JSpacing.sm,
                  children: [for (final s in p.skills) _SkillChip(label: s)],
                ),
              ),
            ],
            const SizedBox(height: JSpacing.xl),
            JEntrance(
              delay: const Duration(milliseconds: 400),
              child: const _SectionTitle('Reviews'),
            ),
            const SizedBox(height: JSpacing.md),
            // Designed empty state — S7 will replace it with a review list.
            JEntrance(
              delay: const Duration(milliseconds: 460),
              child: JCard(
                child: JEmptyState(
                  icon: LucideIcons.star,
                  title: 'No reviews yet',
                  body:
                      "This tasker hasn't finished a job on JOBBees yet. Once "
                      "clients leave feedback, it'll appear here.",
                ),
              ),
            ),
            const SizedBox(height: JSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like the public profile: avatar + name, trust
/// badges, rate, and an About block. Skeleton, not a spinner.
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
                    JSkeleton.line(width: 140, height: 20),
                    SizedBox(height: JSpacing.sm),
                    JSkeleton.line(width: 100),
                  ],
                ),
              ],
            ),
            SizedBox(height: JSpacing.lg),
            Row(
              children: [
                JSkeleton.box(width: 120, height: 26, radius: JRadius.chipAll),
                SizedBox(width: JSpacing.sm),
                JSkeleton.box(width: 120, height: 26, radius: JRadius.chipAll),
              ],
            ),
            SizedBox(height: JSpacing.lg),
            JSkeleton.line(width: 80, height: 20),
            SizedBox(height: JSpacing.lg),
            JSkeleton.line(width: 80),
            SizedBox(height: JSpacing.sm),
            JSkeleton.line(),
            SizedBox(height: JSpacing.sm),
            JSkeleton.line(),
            SizedBox(height: JSpacing.sm),
            JSkeleton.line(width: 220),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return JAvatar(initials: initial, size: 64);
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.badges});

  final TaskerBadges badges;

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (badges.email) 'Email verified',
      if (badges.phone) 'Phone verified',
      if (badges.payments) 'Payments ready',
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: JSpacing.sm,
      runSpacing: JSpacing.sm,
      children: [for (final label in items) _BadgeChip(label: label)],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: JSpacing.md,
        vertical: JSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: JRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.badgeCheck, size: 14, color: scheme.primary),
          const SizedBox(width: JSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: JSpacing.base,
        vertical: JSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: JRadius.chipAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Full-screen error state — Charter § 7 (designed error state, not red text).
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: JEmptyState(
        icon: LucideIcons.cloudOff,
        title: "We couldn't load this profile",
        body:
            'Check your connection and give it another go. If it keeps '
            "happening, tap Support in Settings and we'll take a look.",
        primaryAction: JButton.primary(label: 'Try again', onPressed: onRetry),
      ),
    );
  }
}
