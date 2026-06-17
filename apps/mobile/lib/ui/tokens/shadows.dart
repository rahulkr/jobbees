/// Shadow tokens — layered, brand-tinted soft shadows.
///
/// 2026-refined depth: instead of a single hard drop shadow, every elevated
/// surface gets two stacked layers — a tight low-opacity *contact* shadow plus
/// a wider, softer *ambient* shadow. The tint is the brand navy (`dark900`)
/// rather than pure black, which reads softer and more designed.
///
/// Shadows are for LIGHT mode only. In dark mode, elevation is expressed as
/// surface lightness (see `JCard`), never shadow — shadows are invisible on a
/// near-black background.
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Elevation.

import 'package:flutter/widgets.dart';

import '../../theme/colors.dart';

class JShadows {
  JShadows._();

  /// Navy-tinted shadow base — softer than pure black.
  static const _tint = JobbeesColors.dark900;

  /// Resting elevation — cards, raised tiles. Barely-there lift.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.05),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.07),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  /// Lifted elevation — modal-like surfaces, elevated cards, menus.
  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
}
