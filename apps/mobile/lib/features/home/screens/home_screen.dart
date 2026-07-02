// ignore_for_file: public_member_api_docs

/// Home tab — the authenticated landing surface inside the bottom-nav shell.
///
/// Navigation lives in the shell's [NavigationBar] + Post FAB (see
/// ScaffoldWithNavBar), so this is just the Home tab's content. The real
/// client/tasker feed (job discovery, activity) arrives in Sprint 3+; for now
/// a designed placeholder that hints at where the feed will live rather than
/// a plain "welcome" text.
///
/// Design (per Design Quality Charter § Home feed):
///   * Quiet header (no AppBar chrome; time-of-day greeting + a hint
///     of the user's next action) — the future feed will grow *underneath* it.
///   * Designed placeholder with real microcopy, not a spinner.
///   * Staggered entrance so the screen unfolds on tab-switch.
///
/// When Sprint 3 delivers the feed, replace `_HomePlaceholder` with the feed
/// widget. The header stays.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No AppBar — the shell owns nav; the header lives inside the body so
    // it can scroll with the future feed underneath.
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => const _HomeBody(maxWidth: double.infinity),
          expanded: (context) => const Center(child: _HomeBody(maxWidth: 480)),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              JSpacing.lg,
              JSpacing.lg,
              JSpacing.lg,
              JSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: JEntrance(child: const _Greeting()),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: JSpacing.lg,
                vertical: JSpacing.lg,
              ),
              child: Center(
                child: JEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: const _HomePlaceholder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time-of-day greeting.
///
/// AEST — the app targets Australia by default; the greeting reads the
/// device's local time, which for AU users == AEST/AEDT. If we ship abroad
/// later, this becomes a Riverpod provider that reads user timezone from
/// the session.
class _Greeting extends StatelessWidget {
  const _Greeting();

  String _period() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _period(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'What needs doing?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Designed empty state that hints where the feed will live (Sprint 3+).
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const JEmptyState(
      icon: LucideIcons.compass,
      title: 'Your feed is warming up',
      body:
          "Once you post a job or start hunting for work, we'll show your "
          'activity here. Tap the Post button below to get started.',
    );
  }
}
