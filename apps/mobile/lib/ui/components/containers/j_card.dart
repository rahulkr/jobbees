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

library;

import 'package:flutter/material.dart';
import '../../platform/j_pressable.dart';
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
  }) => JCard(padding: padding, onTap: onTap, key: key, child: child);

  /// Elevated card variant — for modals + overlays only.
  /// Default flat-with-border is preferred everywhere else.
  factory JCard.elevated({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(JSpacing.base),
    Key? key,
  }) => JCard(padding: padding, elevated: true, key: key, child: child);

  final Widget child;
  final EdgeInsets padding;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    // Dark-mode elevation is expressed as lightness, not shadow: a raised
    // surface steps *up* the neutral ramp so it separates from the near-black
    // background. Light mode keeps the original white-card-on-white look.
    // Elevated cards step one tone higher still.
    final Color fill = isDark
        ? (elevated ? scheme.surfaceContainerHigh : scheme.surfaceContainer)
        : scheme.surface;

    // Shadows read on light backgrounds but vanish on dark ones, so dark cards
    // always keep a hairline for definition; light flat cards rely on it too.
    final bool showBorder = isDark || !elevated;
    final Color borderColor = isDark ? scheme.outline : scheme.outlineVariant;

    final card = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: JRadius.cardAll,
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
        boxShadow: elevated && !isDark ? JShadows.lifted : null,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return JPressable(onTap: onTap, haptic: false, child: card);
    }
    return card;
  }
}
