// ignore_for_file: public_member_api_docs

/// Biometric unlock gate (inventory rows 9 / 235, Lean).
///
/// Shown on cold launch when a returning user has biometric unlock enabled and
/// a session was restored. It auto-prompts Face ID / Touch ID / fingerprint; a
/// pass clears the app-lock and the router drops the user into the app. The
/// fallback is to sign out and log in with a password. The screen never
/// navigates itself — it flips lock / session state and the router redirect
/// reacts (CLAUDE.md rule 5). No AppBar: there is nowhere to go back to.
///
/// Design (per Design Quality Charter): hero entrance on the fingerprint mark,
/// with a subtle continuous pulse while the biometric prompt is on-screen so
/// the user perceives the app as *listening*. Failure gets a distinct icon +
/// warmer copy — this is a security screen so it must feel humane, not scary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';
import '../providers/biometric_providers.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  bool _failed = false;

  /// Slow breathing on the fingerprint container while the prompt is up. The
  /// controller keeps ticking even when the animation isn't visible; toggling
  /// it costs less than allocating on every state change.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reduced motion — hold the mark still (CLAUDE.md motion rule).
      if (!MediaQuery.of(context).disableAnimations) {
        _pulse.repeat(reverse: true);
      }
      // Auto-prompt on mount so unlocking is a single Face ID tap, not two.
      _unlock();
    });
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await ref
        .read(biometricAuthServiceProvider)
        .authenticate(reason: 'Unlock JOBBees');
    if (!mounted) return;
    if (ok) {
      // Clears the lock; the router redirect drops us into the app.
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    JHaptics.error();
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  Future<void> _usePassword() async {
    // Free the lock so the next login isn't met by the gate again this session,
    // then sign out — the router returns to login.
    ref.read(appLockProvider.notifier).unlock();
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(context, maxWidth: double.infinity),
          expanded: (context) => Center(child: _body(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, {required double maxWidth}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _failed ? scheme.error : scheme.primary;
    final accentBg = _failed ? scheme.errorContainer : scheme.primaryContainer;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: JSpacing.xxl),
              // Hero mark — enters, then pulses while the prompt is up.
              JEntrance(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      // Only pulse while the OS prompt is up. When idle after
                      // a failed attempt, hold still.
                      final active = _busy;
                      final t = CurvedAnimation(
                        parent: _pulse,
                        curve: Curves.easeInOut,
                      ).value;
                      final scale = active ? 1.0 + 0.06 * t : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: JRadius.heroAll,
                      ),
                      child: Icon(
                        _failed ? LucideIcons.lock : LucideIcons.fingerprint,
                        size: 44,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  _failed ? "Let's try that again" : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  _failed
                      ? 'We could not verify it was you. Have another go, or '
                            'sign in with your password.'
                      : 'Unlock JOBBees to continue.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 240),
                child: JButton.primary(
                  label: 'Unlock',
                  onPressed: _busy ? null : _unlock,
                  loading: _busy,
                  expanded: true,
                  size: JButtonSize.lg,
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                delay: const Duration(milliseconds: 300),
                child: JButton.ghost(
                  label: 'Use password instead',
                  onPressed: _busy ? null : _usePassword,
                  expanded: true,
                  size: JButtonSize.lg,
                  neutral: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
