/// Showcase — a composed Home-feed screen.
///
/// NOT a shipped feature (the real feed is built in Sprint 4). This is a design
/// artifact: it shows the JOBBees design language applied in context — gradient
/// hero, bold type hierarchy, job cards with budget pills + chips + rating —
/// so the look-and-feel can be judged on a real screen, not isolated atoms.
///
/// Toggle Light/Dark in the Widgetbook toolbar to review both themes.

library;

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/theme/colors.dart';
import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent homeFeedShowcase() {
  return WidgetbookComponent(
    name: 'Home feed (composed)',
    useCases: [
      WidgetbookUseCase(
        name: 'Client home',
        builder: (ctx) => const _PhoneFrame(child: _HomeFeed()),
      ),
    ],
  );
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLowest,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 412),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        JSpacing.lg,
        JSpacing.xxl,
        JSpacing.lg,
        JSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradientPrimary,
                  borderRadius: JRadius.buttonMdAll,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: JSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text('What needs doing?', style: text.titleLarge),
                  ],
                ),
              ),
              _IconChip(icon: Icons.notifications_none_rounded, scheme: scheme),
            ],
          ),
          const SizedBox(height: JSpacing.lg),

          // ---- Gradient hero CTA ----
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradientPrimary,
              borderRadius: JRadius.heroAll,
              boxShadow: theme.brightness == Brightness.light
                  ? JShadows.lifted
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(JSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post a job in 60 seconds',
                          style: text.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: JSpacing.xs),
                        Text(
                          'Speak it, snap a photo, or type it.',
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: JSpacing.base),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JSpacing.xl),

          // ---- Section header ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular near you', style: text.titleMedium),
              Text(
                'See all',
                style: text.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: JSpacing.md),

          // ---- Featured job card ----
          JCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: JRadius.buttonMdAll,
                      ),
                      child: Icon(
                        Icons.tv_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: JSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mount a 65" TV on the wall',
                            style: text.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: JobbeesColors.warning,
                              ),
                              const SizedBox(width: 2),
                              Text('4.9', style: text.labelMedium),
                              Text(
                                '  ·  2.1 km away',
                                style: text.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _Pill(
                      label: '\$120',
                      bg: scheme.primary.withValues(alpha: 0.12),
                      fg: scheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: JSpacing.md),
                Wrap(
                  spacing: JSpacing.sm,
                  children: [
                    _Pill(
                      label: 'Handyman',
                      bg: scheme.surfaceContainerHighest,
                      fg: scheme.onSurfaceVariant,
                    ),
                    _Pill(
                      label: 'Today · 2pm',
                      bg: scheme.surfaceContainerHighest,
                      fg: scheme.onSurfaceVariant,
                    ),
                    _Pill(
                      label: 'Indoor',
                      bg: scheme.surfaceContainerHighest,
                      fg: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: JSpacing.base),
                JButton.primary(
                  label: 'Make an offer',
                  gradient: true,
                  expanded: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: JSpacing.md),

          // ---- Compact feed cell ----
          JCard.tappable(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: JRadius.buttonMdAll,
                  ),
                  child: Icon(
                    Icons.chair_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: JSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assemble an Ikea bookshelf',
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Surry Hills · Tomorrow',
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  label: '\$60',
                  bg: scheme.primary.withValues(alpha: 0.12),
                  fg: scheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: JSpacing.md, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: JRadius.chipAll),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.scheme});
  final IconData icon;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: JRadius.buttonMdAll,
      ),
      child: Icon(icon, size: 22, color: scheme.onSurface),
    );
  }
}
