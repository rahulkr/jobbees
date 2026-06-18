// ignore_for_file: public_member_api_docs

/// Role selection (inventory row 14).
///
/// First onboarding beat after the welcome carousel: the user picks how they'll
/// start — get a job done (CLIENT) or earn as a tasker (TASKER) — or defers the
/// choice. The selection flows into signup as a query param so the account is
/// created with the right role; "decide later" omits it (backend defaults
/// CLIENT, and they can become a tasker any time).
///
/// Navigation between two public auth screens is plain `context.go` — the
/// state-driven rule (CLAUDE.md rule 5) governs auth transitions, not stepping
/// through the signed-out funnel.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/platform/j_pressable.dart';
import '../../../ui/ui.dart';
import '../widgets/auth_header.dart';

class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.icon,
    required this.title,
    required this.blurb,
  });

  /// Wire value passed to signup as `?role=`.
  final String role;
  final IconData icon;
  final String title;
  final String blurb;
}

const List<_RoleOption> _options = [
  _RoleOption(
    role: 'client',
    icon: Icons.assignment_outlined,
    title: 'Get a job done',
    blurb: 'Post a task and hire a local tasker.',
  ),
  _RoleOption(
    role: 'tasker',
    icon: Icons.handyman_outlined,
    title: 'Earn as a tasker',
    blurb: 'Find work and get paid for your skills.',
  ),
];

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _select(String role) {
    setState(() => _selectedRole = role);
  }

  void _continue() {
    if (_selectedRole == null) return;
    context.go('/auth/signup?role=$_selectedRole');
  }

  void _decideLater() => context.go('/auth/signup');

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
    final selected = _selectedRole;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(JSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: JSpacing.lg),
            const AuthHeader(
              title: 'How will you start?',
              subtitle:
                  'You can do both later. This just sets up your first '
                  'experience.',
            ),
            const SizedBox(height: JSpacing.xl),
            for (final option in _options) ...[
              _RoleCard(
                option: option,
                selected: selected == option.role,
                onTap: () => _select(option.role),
              ),
              const SizedBox(height: JSpacing.base),
            ],
            const Spacer(),
            JButton.primary(
              label: selected == null
                  ? 'Pick one to continue'
                  : 'Continue as a ${_labelFor(selected)}',
              onPressed: selected == null ? null : _continue,
              expanded: true,
              size: JButtonSize.lg,
            ),
            const SizedBox(height: JSpacing.sm),
            JButton.ghost(
              label: "I'll decide later",
              onPressed: _decideLater,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String role) => role == 'tasker' ? 'tasker' : 'client';
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '${option.title}. ${option.blurb}',
      child: JPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: JMotion.pageTransition,
          curve: JMotion.easeOut,
          padding: const EdgeInsets.all(JSpacing.base),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: JRadius.cardAll,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: JRadius.buttonLgAll,
                ),
                child: Icon(
                  option.icon,
                  size: 28,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: JSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: JSpacing.xs),
                    Text(
                      option.blurb,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: JSpacing.sm),
              // Color is never the only signal (a11y): the ring + fill change
              // too, but the check makes selection unmistakable.
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: JMotion.pressFeedback,
                curve: JMotion.spring,
                child: Icon(Icons.check_circle, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
