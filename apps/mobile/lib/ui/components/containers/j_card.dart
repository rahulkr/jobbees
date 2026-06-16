/// JCard — the standard card container.
///
/// Default is flat (no elevation, no shadow), with a subtle 1px border.
/// Brand corner radius (24px).
///
/// Variants:
///   JCard() — flat with border (default — use everywhere)
///   JCard.elevated() — for modal-like surfaces only (rare)
///   JCard.tappable(onTap: ...) — full-bleed tap target (list cards, etc.)
///
/// Reference: docs/brand/UI-PRINCIPLES.md § Elevation, § Cards.

import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';

class JCard extends StatelessWidget {
  const JCard({
    required this.child,
    this.padding = const EdgeInsets.all(JSpacing.base),
    this.elevated = false,
    this.onTap,
    super.key,
  });

  /// Tappable card variant — convenience for list rows / job cards.
  factory JCard.tappable({
    required Widget child,
    required VoidCallback onTap,
    EdgeInsets padding = const EdgeInsets.all(JSpacing.base),
    Key? key,
  }) =>
      JCard(
        padding: padding,
        onTap: onTap,
        key: key,
        child: child,
      );

  /// Elevated card variant — for modals + overlays only.
  /// Default flat-with-border is preferred everywhere else.
  factory JCard.elevated({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(JSpacing.base),
    Key? key,
  }) =>
      JCard(
        padding: padding,
        elevated: true,
        key: key,
        child: child,
      );

  final Widget child;
  final EdgeInsets padding;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: JRadius.cardAll,
        border: elevated ? null : Border.all(color: scheme.outlineVariant, width: 1),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: JRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: JRadius.cardAll,
          child: card,
        ),
      );
    }
    return card;
  }
}
