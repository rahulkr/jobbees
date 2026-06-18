// ignore_for_file: public_member_api_docs

/// Email verification landing (inventory row 12).
///
/// Reached from the verification email link (`/auth/verify-email?token=...`).
/// Verifies the token on load, then shows a success or expired-link state.
/// "Continue" routes to home if a session is live, otherwise to login. A
/// missing token short-circuits to the expired-link state.
///
/// The verification email is sent by the backend on signup; the in-app
/// "resend / verify your email" prompt is a separate follow-up.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_notice.dart';

enum _Status { verifying, verified, failed }

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.token, super.key});

  /// Token from the verification email link; null/empty fails immediately.
  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  _Status _status = _Status.verifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _status = _Status.failed);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).verifyEmail(token);
      if (mounted) setState(() => _status = _Status.verified);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.failed);
    }
  }

  void _continue() {
    final signedIn = ref.read(authControllerProvider).valueOrNull != null;
    context.go(signedIn ? '/' : '/auth/login');
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: switch (_status) {
            _Status.verifying => const _Verifying(),
            _Status.verified => AuthNotice(
              icon: LucideIcons.badgeCheck,
              title: 'Email verified',
              body: 'Your email address is confirmed.',
              ctaLabel: 'Continue',
              onCta: _continue,
            ),
            _Status.failed => AuthNotice(
              icon: LucideIcons.unlink,
              title: 'This link has expired',
              body:
                  'Verification links are single-use and time-limited. Sign in '
                  'and request a new one.',
              ctaLabel: 'Go to login',
              onCta: () => context.go('/auth/login'),
            ),
          },
        ),
      ),
    );
  }
}

class _Verifying extends StatelessWidget {
  const _Verifying();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: JSpacing.xxxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
