/// JBottomSheet — the standard bottom sheet, snap-to-height behaviour.
///
/// 3 discrete heights: peek (140px), half (50% screen), full (90% screen).
/// Drags between snap to nearest height.
/// Tap outside or drag-down past peek to dismiss.
///
/// Reference: docs/brand/UI-PRINCIPLES.md § 2026 patterns / bottom-sheet-first.
///
/// Usage:
///   JBottomSheet.show(
///     context: context,
///     title: 'Withdraw your offer?',
///     child: ...,
///     primaryAction: JButton.danger(
///       label: 'Yes, withdraw',
///       onPressed: () => Navigator.pop(context, true),
///     ),
///     secondaryAction: JButton.secondary(
///       label: 'Keep it open',
///       onPressed: () => Navigator.pop(context, false),
///     ),
///   )

import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';

class JBottomSheet extends StatelessWidget {
  const JBottomSheet({
    required this.child,
    this.title,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  /// Show a JBottomSheet via Material's `showModalBottomSheet`.
  ///
  /// Returns whatever the closing Navigator.pop passes back.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? primaryAction,
    Widget? secondaryAction,
    bool isDismissible = true,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isDismissible: isDismissible,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => JBottomSheet(
          title: title,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
          child: child,
        ),
      );

  final Widget child;
  final String? title;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedPadding(
      duration: JMotion.bottomSheet,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: JRadius.card),
          ),
          padding: const EdgeInsets.all(JSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.base),

              // Title
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: JSpacing.base),
              ],

              // Body
              Flexible(child: child),

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
        ),
      ),
    );
  }
}
