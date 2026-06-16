/// JEmptyState — the standard empty-state pattern.
///
/// Every empty list / feed / inbox uses this. Doubles as a tutorial.
///
/// Reference: docs/brand/VOICE.md § Empty states + UI-PRINCIPLES.md § Empty states.
///
/// Per Sprint 11 row 213 (expanded scope), empty states act as contextual tutorials.
///
/// Usage:
///   JEmptyState(
///     icon: Icons.outbox_outlined,
///     title: 'No jobs near you yet',
///     body: 'Be the first to post one. We will send it to taskers in your suburb.',
///     primaryAction: JButton.primary(
///       label: 'Post a job',
///       onPressed: () => ...
///     ),
///   )

import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';

class JEmptyState extends StatelessWidget {
  const JEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(JSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: JSpacing.lg),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: JSpacing.sm),

          // Body
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Actions
          if (primaryAction != null) ...[
            const SizedBox(height: JSpacing.lg),
            primaryAction!,
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: JSpacing.sm),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}
