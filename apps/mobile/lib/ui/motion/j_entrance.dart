/// JEntrance — the standard on-mount entrance animation.
///
/// Fade in from 0 → 1, slide up 8px. 400ms, ease-out. Respects reduced motion
/// (renders the destination state immediately when the OS asks for it).
///
/// Use to stagger elements into place on screen mount. Pass an increasing
/// [delay] to each sibling to compose the stagger:
///
///   JEntrance(delay: Duration.zero, child: header),
///   JEntrance(delay: Duration(milliseconds: 80), child: body),
///   JEntrance(delay: Duration(milliseconds: 160), child: cta),
///
/// Reference: docs/brand/UI-PRINCIPLES.md § Motion, docs/brand/DESIGN-QUALITY-CHARTER.md § entrance animation.

library;

import 'package:flutter/material.dart';

import '../tokens/motion.dart';

class JEntrance extends StatefulWidget {
  const JEntrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 8,
    super.key,
  });

  final Widget child;

  /// Wait this long after mount before starting the animation.
  /// Compose stagger by giving siblings increasing delays.
  final Duration delay;

  /// Animation duration.
  final Duration duration;

  /// Vertical translation offset in pixels (positive = starts below and slides up).
  final double offset;

  @override
  State<JEntrance> createState() => _JEntranceState();
}

class _JEntranceState extends State<JEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Reduced motion — skip the animation entirely, render destination state.
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
        return;
      }
      if (widget.delay > Duration.zero) {
        await Future<void>.delayed(widget.delay);
        if (!mounted) return;
      }
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: JMotion.easeOut,
        ).value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
