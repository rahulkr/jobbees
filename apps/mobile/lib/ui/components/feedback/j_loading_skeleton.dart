/// JSkeleton + JShimmer — content-shaped loading placeholders.
///
/// The 2026 loading language: show a grey placeholder in the *shape* of the
/// content that's coming, with a soft highlight sweeping across it. Never a bare
/// spinner for content with a predictable shape (lists, forms, profiles).
/// Spinners stay only for button presses and shapeless one-shot waits.
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Loading states /
/// "Skeleton everywhere, spinners almost never".
///
/// Usage — wrap a tree of [JSkeleton] shapes in a single [JShimmer] so one
/// sweep runs across the whole group:
///
///   JShimmer(
///     child: Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: const [
///         JSkeleton.line(width: 160),                // a title line
///         SizedBox(height: JSpacing.sm),
///         JSkeleton.line(),                          // full-width body line
///         JSkeleton.box(height: 56),                 // a field
///         JSkeleton.circle(size: 64),                // an avatar
///       ],
///     ),
///   )
///
/// Reduced motion: when `MediaQuery.disableAnimations` is set, [JShimmer]
/// renders the static grey shapes with no sweep (per UI-PRINCIPLES § Reduced
/// motion — informational placeholders stay, decorative motion goes).

library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../tokens/tokens.dart';

/// The neutral base colour for skeleton shapes — a calm step up the surface
/// ramp so the placeholder reads as "content pending", in light and dark.
Color _skeletonBase(ColorScheme scheme) => scheme.brightness == Brightness.light
    ? scheme.surfaceContainerHigh
    : scheme.surfaceContainer;

/// The lighter band the shimmer sweeps across the base.
Color _skeletonHighlight(ColorScheme scheme) =>
    scheme.brightness == Brightness.light
    ? scheme.surfaceContainerLowest
    : scheme.surfaceContainerHighest;

/// A single skeleton shape: a rounded box, a text line, or a circle.
///
/// Draws itself in the neutral base colour so it still reads as a placeholder
/// when shown statically (reduced motion) or outside a [JShimmer].
class JSkeleton extends StatelessWidget {
  /// A block placeholder — fields, buttons, images, status chips.
  const JSkeleton.box({
    required this.height,
    this.width = double.infinity,
    this.radius = JRadius.buttonMdAll,
    super.key,
  }) : shape = BoxShape.rectangle;

  /// A text-line placeholder. Pill radius so it reads as a line of copy.
  const JSkeleton.line({
    this.width = double.infinity,
    this.height = 14,
    super.key,
  }) : radius = const BorderRadius.all(Radius.circular(7)),
       shape = BoxShape.rectangle;

  /// A circular placeholder — avatars, icon badges.
  const JSkeleton.circle({required double size, super.key})
    : width = size,
      height = size,
      radius = null,
      shape = BoxShape.circle;

  final double width;
  final double height;
  final BorderRadius? radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _skeletonBase(Theme.of(context).colorScheme),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius,
      ),
    );
  }
}

/// Wraps a tree of [JSkeleton] shapes in one shimmer sweep.
///
/// Apply a single JShimmer around the whole placeholder group (not one per
/// shape) so the highlight travels across everything together — that's what
/// reads as a loading surface rather than N independent twinkles. Keep real
/// card chrome (borders, dividers) *outside* the JShimmer so only the
/// placeholders shimmer.
class JShimmer extends StatelessWidget {
  const JShimmer({required this.child, super.key});

  final Widget child;

  /// Calm, slightly-slow sweep — fast shimmer reads as anxious.
  static const Duration _period = Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    // Reduced motion: show the static grey shapes, no sweep.
    if (MediaQuery.of(context).disableAnimations) return child;

    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: _skeletonBase(scheme),
      highlightColor: _skeletonHighlight(scheme),
      period: _period,
      child: child,
    );
  }
}
