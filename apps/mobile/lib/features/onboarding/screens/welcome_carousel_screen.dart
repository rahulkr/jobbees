// ignore_for_file: public_member_api_docs

/// Welcome carousel (inventory row 527).
///
/// Three first-launch slides explaining what JOBBees does. Skippable; finishing
/// or skipping marks the carousel seen ([welcomeSeenProvider]) which the router
/// reacts to by redirecting home — this screen never navigates itself
/// (CLAUDE.md rule 5).
///
/// Design (per Design Quality Charter § Onboarding):
///   * Each slide has a *personality* — an icon container that gently breathes
///     while the slide is active, plus staggered entrance on icon/title/body
///     so revealing a new slide feels intentional rather than a flat swap.
///   * Skip is present but fades out on the last slide (can't skip to the end
///     when you're already there).
///   * Elongating page indicator (already good — kept).
///
/// Content-only by nature: the slides are static local copy, so the four-state
/// pattern (CLAUDE.md rule 3) collapses to the content state — there's no
/// async load, error, or empty case to render.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/onboarding_providers.dart';

/// One carousel slide. Australian voice per docs/brand/VOICE.md.
@immutable
class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const List<_Slide> _slides = [
  _Slide(
    icon: LucideIcons.clipboardList,
    title: 'Post a job in minutes',
    body:
        'Describe what you need done. Local taskers send you offers, and you '
        'pick who does it.',
  ),
  _Slide(
    icon: LucideIcons.hammer,
    title: 'Earn on your terms',
    body:
        'Become a tasker, choose the jobs that suit you, and get paid securely '
        'once the work is done.',
  ),
  _Slide(
    icon: LucideIcons.shieldCheck,
    title: 'Safe and local',
    body:
        'Verified taskers, secure payments, and support based right here in '
        'Australia.',
  ),
];

class WelcomeCarouselScreen extends ConsumerStatefulWidget {
  const WelcomeCarouselScreen({super.key});

  @override
  ConsumerState<WelcomeCarouselScreen> createState() =>
      _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends ConsumerState<WelcomeCarouselScreen> {
  // PageController + current index are screen-local UI state, so a plain
  // controller here is fine (CLAUDE.md rule 4 reserves Riverpod for app state).
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastSlide => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() => ref.read(welcomeSeenProvider.notifier).markSeen();

  void _next() {
    if (_isLastSlide) {
      _finish();
      return;
    }
    JHaptics.navigation();
    final target = _index + 1;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: JMotion.pageTransition,
        curve: JMotion.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _buildBody(context, maxWidth: double.infinity),
          expanded: (context) =>
              Center(child: _buildBody(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required double maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: _isLastSlide ? 0 : 1,
              duration: JMotion.snackbar,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: JSpacing.sm,
                  right: JSpacing.sm,
                ),
                // Disabled (not just hidden) on the last slide so it can't be
                // tapped while faded out.
                child: JButton.ghost(
                  label: 'Skip',
                  onPressed: _isLastSlide ? null : _finish,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                JHaptics.navigation();
              },
              itemBuilder: (context, i) => _SlideView(
                // Keyed so title/body remount + JEntrance re-plays on slide switch.
                key: ValueKey('slide-$i'),
                slide: _slides[i],
                isActive: i == _index,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(JSpacing.lg),
            child: Column(
              children: [
                _PageIndicator(count: _slides.length, index: _index),
                const SizedBox(height: JSpacing.lg),
                JButton.primary(
                  label: _isLastSlide ? 'Get started' : 'Next',
                  onPressed: _next,
                  expanded: true,
                  size: JButtonSize.lg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatefulWidget {
  const _SlideView({required this.slide, required this.isActive, super.key});

  final _Slide slide;

  /// True when this slide is the currently-visible one. Used to keep the
  /// breathing icon animation only on the visible slide (nothing off-screen
  /// should burn frames).
  final bool isActive;

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant _SlideView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.isActive && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: JSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          JEntrance(
            child: AnimatedBuilder(
              animation: _breath,
              builder: (context, child) {
                final t = CurvedAnimation(
                  parent: _breath,
                  curve: Curves.easeInOut,
                ).value;
                // 1.0 → 1.04 → 1.0 — a subtle breath, not a bounce.
                final scale = 1.0 + (widget.isActive ? 0.04 * t : 0);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: JRadius.heroAll,
                ),
                child: Icon(widget.slide.icon, size: 56, color: scheme.primary),
              ),
            ),
          ),
          const SizedBox(height: JSpacing.xl),
          JEntrance(
            delay: const Duration(milliseconds: 90),
            child: Text(
              widget.slide.title,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: JSpacing.md),
          JEntrance(
            delay: const Duration(milliseconds: 180),
            child: Text(
              widget.slide.body,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: JMotion.pageTransition,
            curve: JMotion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: JSpacing.xs),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: JRadius.chipAll,
            ),
          ),
      ],
    );
  }
}
