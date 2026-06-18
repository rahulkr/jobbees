// ignore_for_file: public_member_api_docs

/// Splash screen (inventory row 1).
///
/// The first frame on a cold launch: a short branded moment, then routing
/// hands off to the welcome carousel (first run) or home. The hand-off flips
/// [splashCompleteProvider]; the router redirect reacts to that, so this widget
/// never pushes a route itself (CLAUDE.md rule 5).
///
/// App-icon / launch-image assets are client-supplied (see apps/mobile
/// CLAUDE.md "What's NOT here"), so the brand wordmark stands in for now.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/colors.dart';
import '../../../ui/ui.dart';
import '../providers/onboarding_providers.dart';

/// How long the brand mark holds before routing continues. Collapsed to zero
/// when the platform requests reduced motion.
const Duration _kSplashHold = Duration(milliseconds: 1200);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame so MediaQuery (reduced-motion) is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hold = MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : _kSplashHold;
      _timer = Timer(hold, () {
        if (mounted) ref.read(splashCompleteProvider.notifier).complete();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: gradientPrimary),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JOBBees',
                  style: textTheme.displayMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: JSpacing.md),
                Text(
                  'Local jobs, done right',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
