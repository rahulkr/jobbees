// ignore_for_file: public_member_api_docs

/// Account-suspended/banned screen (inventory row 18).
///
/// Shown when the API blocks a suspended account at login (a 403 carrying
/// `code: ACCOUNT_SUSPENDED`, surfaced by [AuthController] as a suspended
/// session). A terminal state: the only way out is logging out, which flips the
/// session to signed-out and the router returns the user to login (CLAUDE.md
/// rule 5 — the screen never navigates itself). No AppBar: there is nowhere to
/// go back to.
///
/// Design (per Design Quality Charter § Empty states + the "humane" rule):
///   * Users seeing this screen are already having a bad day. Copy is warm and
///     factual (not corporate), and the hero uses `errorContainer` tones so it
///     reads as *serious* without shouting. No stern-red iconography.
///   * Composed directly (not through AuthNotice) so the moment gets its own
///     staggered entrance and its own two-action layout — "Log out" as the
///     primary and "Contact support" as a soft secondary next to it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';

const String _kSupportEmail = 'support@jobbees.com.au';

/// Opens the user's mail app to contact support. If no mail app can be launched
/// (or it throws), fall back to copying the address so the path is never dead.
Future<void> _contactSupport(BuildContext context) async {
  final uri = Uri(scheme: 'mailto', path: _kSupportEmail);
  try {
    if (await launchUrl(uri)) return;
  } catch (_) {
    // No mail handler — fall through to the clipboard fallback below.
  }
  if (!context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: _kSupportEmail));
  if (context.mounted) {
    JSnackbar.showSuccess(context, 'Support email copied to your clipboard');
  }
}

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
              // Hero mark — `errorContainer` tones so it reads serious, not
              // shouting-red. A shield icon signals "protective pause", not
              // punishment.
              JEntrance(
                child: const Center(
                  child: JHeroMark(
                    icon: LucideIcons.shieldAlert,
                    tone: JHeroTone.error,
                    size: 88,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 90),
                child: Text(
                  'Your account is paused',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  "We've paused your JOBBees account, so you can't sign in "
                  "right now. If you think this isn't right, get in touch and "
                  "we'll take a look.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              // Support email as a card — it's the actionable path for anyone
              // who thinks this is a mistake, so it deserves its own visual
              // weight rather than being buried in the body copy.
              JEntrance(
                delay: const Duration(milliseconds: 240),
                child: JCard.tappable(
                  onTap: () => _contactSupport(context),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: JRadius.buttonMdAll,
                        ),
                        child: Icon(
                          LucideIcons.mail,
                          size: 22,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: JSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact support',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: JSpacing.xs),
                            Text(
                              _kSupportEmail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              JEntrance(
                delay: const Duration(milliseconds: 320),
                child: JButton.primary(
                  label: 'Log out',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  expanded: true,
                  size: JButtonSize.lg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
