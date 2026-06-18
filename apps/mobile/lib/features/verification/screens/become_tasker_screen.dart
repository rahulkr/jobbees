// ignore_for_file: public_member_api_docs

/// Work-as-a-tasker switch (inventory row 15).
///
/// A client switches on the tasker side of their account here. It is a role
/// switch, not an upgrade that takes anything away: a tasker can do jobs AND
/// still post jobs as a client. Verification (ABN, payouts, phone) is the gate,
/// so confirming sends the account to the verification hub.
///
/// Navigation stays state-driven (CLAUDE.md rule 5) for the auth gate, but this
/// is a deliberate in-flow step, so we `go('/verify')` once the role flips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../../auth/providers/auth_controller.dart';
import '../../auth/widgets/auth_error_banner.dart';

class BecomeTaskerScreen extends ConsumerStatefulWidget {
  const BecomeTaskerScreen({super.key});

  @override
  ConsumerState<BecomeTaskerScreen> createState() => _BecomeTaskerScreenState();
}

class _BecomeTaskerScreenState extends ConsumerState<BecomeTaskerScreen> {
  bool _submitting = false;
  String? _formError;

  Future<void> _start() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).becomeTasker();
      if (mounted) context.go('/verify');
    } on AppError catch (error) {
      if (mounted) setState(() => _formError = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work as a tasker')),
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(context, maxWidth: double.infinity),
          expanded: (context) => Center(child: _body(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, {required double maxWidth}) {
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
              const SizedBox(height: JSpacing.sm),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: JRadius.heroAll,
                ),
                child: Icon(
                  LucideIcons.briefcase,
                  size: 34,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              Text(
                'Find work and get paid',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: JSpacing.sm),
              Text(
                'Taskers do jobs and get paid for their skills. You keep your '
                'account and can still post jobs as a client whenever you like.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              Text(
                "A quick verification first, then you're set:",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: JSpacing.base),
              const _Step(
                icon: LucideIcons.badgeCheck,
                title: 'Verify your ABN',
                blurb: "We check it against the Australian Business Register.",
              ),
              const _Step(
                icon: LucideIcons.wallet,
                title: 'Set up payouts',
                blurb: 'So you can get paid securely once a job is done.',
              ),
              const _Step(
                icon: LucideIcons.smartphone,
                title: 'Verify your phone',
                blurb: 'A quick code keeps your account secure.',
              ),
              const SizedBox(height: JSpacing.sm),
              Row(
                children: [
                  Icon(
                    LucideIcons.arrowLeftRight,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: JSpacing.sm),
                  Expanded(
                    child: Text(
                      'Switch between hiring and working anytime.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: JSpacing.xl),
              if (_formError != null) ...[
                AuthErrorBanner(message: _formError!),
                const SizedBox(height: JSpacing.base),
              ],
              JButton.primary(
                label: 'Get started',
                onPressed: _submitting ? null : _start,
                loading: _submitting,
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

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.blurb});

  final IconData icon;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: JSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: JRadius.buttonMdAll,
            ),
            child: Icon(icon, size: 22, color: scheme.primary),
          ),
          const SizedBox(width: JSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: JSpacing.xs),
                Text(
                  blurb,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
