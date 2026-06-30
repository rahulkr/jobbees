// ignore_for_file: public_member_api_docs

/// Biometric unlock gate (inventory rows 9 / 235, Lean).
///
/// Shown on cold launch when a returning user has biometric unlock enabled and
/// a session was restored. It auto-prompts Face ID / Touch ID / fingerprint; a
/// pass clears the app-lock and the router drops the user into the app. The
/// fallback is to sign out and log in with a password. The screen never
/// navigates itself — it flips lock / session state and the router redirect
/// reacts (CLAUDE.md rule 5). No AppBar: there is nowhere to go back to.
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

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Auto-prompt on mount so unlocking is a single Face ID tap, not two.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
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
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: JRadius.heroAll,
                ),
                child: Icon(
                  LucideIcons.fingerprint,
                  size: 36,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              Text(
                _failed
                    ? 'We could not verify it was you. Try again, or sign in '
                          'with your password.'
                    : 'Unlock JOBBees to continue.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JButton.primary(
                label: 'Unlock',
                onPressed: _busy ? null : _unlock,
                loading: _busy,
                expanded: true,
                size: JButtonSize.lg,
              ),
              const SizedBox(height: JSpacing.sm),
              JButton.ghost(
                label: 'Use password instead',
                onPressed: _busy ? null : _usePassword,
                expanded: true,
                size: JButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
