// ignore_for_file: public_member_api_docs

/// Welcome carousel (inventory row 527).
///
/// Three first-launch slides explaining what JOBBees does. Skippable; finishing
/// or skipping marks the carousel seen ([welcomeSeenProvider]) which the router
/// reacts to by redirecting home — this screen never navigates itself
/// (CLAUDE.md rule 5).
///
/// Content-only by nature: the slides are static local copy, so the four-state
/// pattern (CLAUDE.md rule 3) collapses to the content state — there's no
/// async load, error, or empty case to render.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    icon: Icons.assignment_outlined,
    title: 'Post a job in minutes',
    body:
        'Describe what you need done. Local taskers send you offers — you pick '
        'who does it.',
  ),
  _Slide(
    icon: Icons.handyman_outlined,
    title: 'Earn on your terms',
    body:
        'Become a tasker, choose the jobs that suit you, and get paid securely '
        'once the work is done.',
  ),
  _Slide(
    icon: Icons.verified_user_outlined,
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
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: JSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: JRadius.heroAll,
            ),
            child: Icon(slide.icon, size: 56, color: scheme.primary),
          ),
          const SizedBox(height: JSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: JSpacing.md),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
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
