/// Motion tokens — durations + curves.
///
/// Single source of truth for animation timing across the app.
/// Respect `MediaQuery.disableAnimations` in every consumer.
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Motion.

import 'package:flutter/animation.dart';

class JMotion {
  JMotion._();

  // --- Durations ---

  /// 100ms — button press feedback
  static const Duration pressFeedback = Duration(milliseconds: 100);

  /// 200ms — snackbar
  static const Duration snackbar = Duration(milliseconds: 200);

  /// 250ms — page transition
  static const Duration pageTransition = Duration(milliseconds: 250);

  /// 300ms — bottom sheet appear
  static const Duration bottomSheet = Duration(milliseconds: 300);

  /// 400ms — modal appear
  static const Duration modal = Duration(milliseconds: 400);

  // --- Curves ---

  /// Standard ease-out for most transitions
  static const Curve easeOut = Curves.easeOutCubic;

  /// Smooth slightly-bouncy curve for bottom sheets
  /// (matches Material 3 emphasized motion)
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Spring physics for drag-to-dismiss + reorder
  static const Curve spring = Cubic(0.16, 1, 0.3, 1);
}
