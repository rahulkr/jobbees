import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jLoadingSkeletonPage() {
  return WidgetbookComponent(
    name: 'JLoadingSkeleton',
    useCases: [
      WidgetbookUseCase(
        name: 'Shapes (box / line / circle)',
        builder: (ctx) => const Padding(
          padding: EdgeInsets.all(JSpacing.lg),
          child: JShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JSkeleton.circle(size: 64),
                SizedBox(height: JSpacing.lg),
                JSkeleton.line(width: 200, height: 20),
                SizedBox(height: JSpacing.sm),
                JSkeleton.line(),
                SizedBox(height: JSpacing.sm),
                JSkeleton.line(width: 240),
                SizedBox(height: JSpacing.lg),
                JSkeleton.box(height: 56),
                SizedBox(height: JSpacing.sm),
                JSkeleton.box(width: 96, height: 32, radius: JRadius.chipAll),
              ],
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Tasker profile (form loading)',
        builder: (ctx) => const SingleChildScrollView(
          padding: EdgeInsets.all(JSpacing.lg),
          child: JShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: JSpacing.sm),
                JSkeleton.line(width: 260),
                SizedBox(height: JSpacing.xl),
                JSkeleton.line(width: 88),
                SizedBox(height: JSpacing.sm),
                JSkeleton.box(height: 120),
                SizedBox(height: JSpacing.lg),
                JSkeleton.line(width: 128),
                SizedBox(height: JSpacing.sm),
                JSkeleton.box(height: 56),
                SizedBox(height: JSpacing.lg),
                JSkeleton.line(width: 60),
                SizedBox(height: JSpacing.sm),
                JSkeleton.box(height: 56),
                SizedBox(height: JSpacing.base),
                Row(
                  children: [
                    JSkeleton.box(
                      width: 96,
                      height: 32,
                      radius: JRadius.chipAll,
                    ),
                    SizedBox(width: JSpacing.sm),
                    JSkeleton.box(
                      width: 72,
                      height: 32,
                      radius: JRadius.chipAll,
                    ),
                    SizedBox(width: JSpacing.sm),
                    JSkeleton.box(
                      width: 108,
                      height: 32,
                      radius: JRadius.chipAll,
                    ),
                  ],
                ),
                SizedBox(height: JSpacing.xl),
                JSkeleton.box(height: 56),
              ],
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Public profile (loading)',
        builder: (ctx) => const SingleChildScrollView(
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
                    JSkeleton.box(
                      width: 120,
                      height: 26,
                      radius: JRadius.chipAll,
                    ),
                    SizedBox(width: JSpacing.sm),
                    JSkeleton.box(
                      width: 120,
                      height: 26,
                      radius: JRadius.chipAll,
                    ),
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
        ),
      ),
      WidgetbookUseCase(
        name: 'Verification status (cards loading)',
        builder: (ctx) => ListView(
          padding: const EdgeInsets.all(JSpacing.lg),
          children: const [
            _GhostCard(),
            SizedBox(height: JSpacing.base),
            _GhostCard(),
          ],
        ),
      ),
    ],
  );
}

/// Mirrors the verification screen's loading ghost card: real card chrome kept
/// outside the shimmer, placeholder shapes inside.
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
