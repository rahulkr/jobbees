/// JPressable — adds a springy scale-down on press to any tappable surface.
///
/// The tactile core of the "refined & soft" interaction language: press a
/// button or a card and it dips slightly (0.97) over 100ms, then springs back.
/// Pairs a subtle scale with an optional selection haptic.
///
/// Respects `MediaQuery.disableAnimations` (reduced-motion): when set, the
/// scale is skipped and only the tap + haptic fire.
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Motion + § Haptics.
///
/// Usage:
///   JPressable(onTap: () => ..., child: someWidget)

import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import 'j_haptics.dart';

class JPressable extends StatefulWidget {
  const JPressable({
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.haptic = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Scale applied while pressed. 1.0 disables the dip.
  final double pressedScale;

  /// Fire a selection-click haptic on tap. Off for non-committal surfaces.
  final bool haptic;

  @override
  State<JPressable> createState() => _JPressableState();
}

class _JPressableState extends State<JPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_enabled) return;
    if (widget.haptic) JHaptics.navigation();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scale = (_pressed && _enabled && !reduceMotion) ? widget.pressedScale : 1.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: JMotion.pressFeedback,
        curve: JMotion.spring,
        child: widget.child,
      ),
    );
  }
}
