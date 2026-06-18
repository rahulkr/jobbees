// ignore_for_file: public_member_api_docs

/// Public tasker profile (inventory row 47) — what a client sees: name, trust
/// badges, bio, hourly rate, skills. Reviews show an empty state until S7.
///
/// Read-only; loads via [publicTaskerProfileProvider]. Four-state aware.
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
      appBar: AppBar(title: const Text('Tasker profile')),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
            Row(
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
            const SizedBox(height: JSpacing.base),
            _Badges(badges: p.badges),
            if (p.hourlyRateCents != null) ...[
              const SizedBox(height: JSpacing.lg),
              Text(
                '\$${(p.hourlyRateCents! / 100).toStringAsFixed(p.hourlyRateCents! % 100 == 0 ? 0 : 2)}/hr',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (p.bio != null && p.bio!.isNotEmpty) ...[
              const SizedBox(height: JSpacing.lg),
              _SectionTitle('About'),
              const SizedBox(height: JSpacing.sm),
              Text(p.bio!, style: theme.textTheme.bodyLarge),
            ],
            if (p.skills.isNotEmpty) ...[
              const SizedBox(height: JSpacing.lg),
              _SectionTitle('Skills'),
              const SizedBox(height: JSpacing.sm),
              Wrap(
                spacing: JSpacing.sm,
                runSpacing: JSpacing.sm,
                children: [for (final s in p.skills) _SkillChip(label: s)],
              ),
            ],
            const SizedBox(height: JSpacing.lg),
            _SectionTitle('Reviews'),
            const SizedBox(height: JSpacing.sm),
            Text(
              'No reviews yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        color: scheme.primaryContainer,
        borderRadius: JRadius.chipAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(JSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.cloudOff, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: JSpacing.base),
          Text(
            "Couldn't load this profile.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: JSpacing.lg),
          JButton.secondary(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
