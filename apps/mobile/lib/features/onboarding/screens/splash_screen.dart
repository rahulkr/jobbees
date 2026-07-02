// ignore_for_file: public_member_api_docs

/// Splash screen (inventory row 1).
///
/// The first frame on a cold launch: a short branded moment, then routing
/// hands off to the welcome carousel (first run) or home. The hand-off flips
/// [splashCompleteProvider]; the router redirect reacts to that, so this widget
/// never pushes a route itself (CLAUDE.md rule 5).
///
/// Choreography (~1500ms total, per Design Quality Charter § Splash entrance):
///   0-350ms   — brand mark scales in from 0.86 with an ease-out fade
///   ~400ms    — single soft haptic on completion (the mark "lands")
///   350-650ms — tagline fades up
///   1500ms    — hand-off to router
///
/// The native launch screen (flutter_native_splash) uses the same asset, so
/// there's no white flash before this frame. Reduced motion collapses the
/// entrance and hold to zero so the user sees the destination immediately.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/tokens/tokens.dart';
import '../../../ui/platform/j_haptics.dart';
import '../providers/onboarding_providers.dart';

/// How long the brand mark holds before routing continues. Collapsed to zero
/// when the platform requests reduced motion.
const Duration _kSplashHold = Duration(milliseconds: 1500);

/// Timing constants for the entrance choreography.
const Duration _kMarkEnter = Duration(milliseconds: 350);
const Duration _kTaglineDelay = Duration(milliseconds: 350);
const Duration _kHapticDelay = Duration(milliseconds: 400);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _handoffTimer;
  Timer? _hapticTimer;
  Timer? _taglineTimer;

  late final AnimationController _markController = AnimationController(
    vsync: this,
    duration: _kMarkEnter,
  );

  // Built once, not per frame inside the AnimatedBuilder.
  late final CurvedAnimation _markCurve = CurvedAnimation(
    parent: _markController,
    curve: JMotion.easeOut,
  );

  bool _showTagline = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame so MediaQuery (reduced-motion) is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.of(context).disableAnimations;

      if (reduce) {
        // Skip the choreography — render destination + hand off immediately.
        _markController.value = 1.0;
        setState(() => _showTagline = true);
        _handoffTimer = Timer(Duration.zero, _handoff);
        return;
      }

      _markController.forward();
      _hapticTimer = Timer(_kHapticDelay, JHaptics.selection);
      _taglineTimer = Timer(_kTaglineDelay, () {
        if (mounted) setState(() => _showTagline = true);
      });
      _handoffTimer = Timer(_kSplashHold, _handoff);
    });
  }

  void _handoff() {
    if (mounted) ref.read(splashCompleteProvider.notifier).complete();
  }

  @override
  void dispose() {
    _handoffTimer?.cancel();
    _hapticTimer?.cancel();
    _taglineTimer?.cancel();
    _markCurve.dispose();
    _markController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // Dark-mode-only: a soft radial warmth behind the mark so the black
          // background reads intentional rather than empty. In light mode this
          // vanishes and the mark carries the frame.
          if (isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.7,
                    colors: [
                      scheme.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand mark — scales from 0.86 with fade. `Image.asset`
                  // deliberately kept so a designer can swap the logo without
                  // touching Flutter code.
                  AnimatedBuilder(
                    animation: _markController,
                    builder: (context, child) {
                      final curved = _markCurve.value;
                      final scale = 0.86 + (0.14 * curved);
                      return Opacity(
                        opacity: curved,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/branding/splash_logo.png',
                      width: 280,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(height: JSpacing.lg),
                  // Tagline eases up after the mark lands.
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: JMotion.easeOut,
                    offset: _showTagline ? Offset.zero : const Offset(0, 0.4),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showTagline ? 1.0 : 0.0,
                      child: Text(
                        'Local jobs, done right',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
