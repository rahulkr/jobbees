/// Border radius scale — 12/16/24/32.
///
/// Single source of truth for corner radii.
/// Naming follows `docs/brand/UI-PRINCIPLES.md` § Shape.

import 'package:flutter/widgets.dart';

class JRadius {
  JRadius._();

  /// 12 — small chips, tags, badges
  static const Radius chip = Radius.circular(12);

  /// 16 — default button corner
  static const Radius buttonMd = Radius.circular(16);

  /// 24 — hero button, cards, modals
  static const Radius buttonLg = Radius.circular(24);
  static const Radius card = Radius.circular(24);

  /// 32 — hero icon containers, large avatars
  static const Radius hero = Radius.circular(32);

  /// Helpers — full BorderRadius for common cases
  static const BorderRadius chipAll = BorderRadius.all(chip);
  static const BorderRadius buttonMdAll = BorderRadius.all(buttonMd);
  static const BorderRadius buttonLgAll = BorderRadius.all(buttonLg);
  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius heroAll = BorderRadius.all(hero);
}
