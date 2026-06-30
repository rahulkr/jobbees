// ignore_for_file: public_member_api_docs

/// Account-suspended/banned screen (inventory row 18).
///
/// Shown when the API blocks a suspended account at login (a 403 carrying
/// `code: ACCOUNT_SUSPENDED`, surfaced by [AuthController] as a suspended
/// session). A terminal state: the only way out is logging out, which flips the
/// session to signed-out and the router returns the user to login (CLAUDE.md
/// rule 5 — the screen never navigates itself). No AppBar: there is nowhere to
/// go back to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_notice.dart';

class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(context, ref, maxWidth: double.infinity),
          expanded: (context) =>
              Center(child: _body(context, ref, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref, {
    required double maxWidth,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: AuthNotice(
            icon: LucideIcons.shieldBan,
            title: 'Account suspended',
            body:
                'Your JOBBees account has been suspended, so you cannot sign in '
                'right now. If you believe this is a mistake, contact us at '
                'support@jobbees.com.au.',
            ctaLabel: 'Log out',
            onCta: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
      ),
    );
  }
}
