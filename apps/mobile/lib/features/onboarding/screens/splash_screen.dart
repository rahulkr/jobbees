// ignore_for_file: public_member_api_docs

/// Splash screen (inventory row 1).
///
/// The first frame on a cold launch: a short branded moment, then routing
/// hands off to the welcome carousel (first run) or home. The hand-off flips
/// [splashCompleteProvider]; the router redirect reacts to that, so this widget
/// never pushes a route itself (CLAUDE.md rule 5).
///
/// Shows the client's brand lockup on a clean light background. The native
/// launch screen (flutter_native_splash) uses the same asset, so there's no
/// white flash before this frame.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/branding/splash_logo.png',
                width: 280,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: JSpacing.lg),
              Text(
                'Local jobs, done right',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
