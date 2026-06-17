/// Spacing scale — 4/8/12/16/24/32/48/64.
///
/// Single source of truth for every padding/margin/gap in the app.
/// Never write a raw number like `EdgeInsets.all(13)` — use these tokens.
///
/// Naming follows the same scale as `docs/brand/UI-PRINCIPLES.md` § Spacing.

library;

class JSpacing {
  JSpacing._();

  /// 4 — icon padding, tight chip gap
  static const double xs = 4;

  /// 8 — item gap in a list
  static const double sm = 8;

  /// 12 — form field inner padding
  static const double md = 12;

  /// 16 — default screen padding, card padding
  static const double base = 16;

  /// 24 — section spacing, card gap
  static const double lg = 24;

  /// 32 — hero spacing, top padding
  static const double xl = 32;

  /// 48 — generous, e.g. between sections in onboarding
  static const double xxl = 48;

  /// 64 — splash centring
  static const double xxxl = 64;
}
