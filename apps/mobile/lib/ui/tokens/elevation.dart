/// Elevation tokens — Material 3 levels 0/1/2/3.
///
/// We use only 4 of M3's 6 levels.
/// Prefer 1px borders to subtle shadows where possible.
///
/// Reference: `docs/brand/UI-PRINCIPLES.md` § Elevation.

class JElevation {
  JElevation._();

  /// 0dp — flat. Most cards, most screens.
  static const double level0 = 0;

  /// 1dp — subtle lift. Use borders instead when possible in light mode.
  static const double level1 = 1;

  /// 3dp — modals, bottom sheets, snackbars.
  static const double level2 = 3;

  /// 6dp — FAB only. Used sparingly for "Post a Job".
  static const double level3 = 6;
}
