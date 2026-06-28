// ignore_for_file: public_member_api_docs

/// JOBBees brand color tokens.
///
/// Carried forward from the React Native prototype's Tailwind config.
/// See `docs/brand/COLORS.md` for usage rules.
///
/// Do NOT introduce new brand colors here without updating `docs/brand/COLORS.md`
/// AND the matching Tailwind tokens in apps/admin + apps/web.

library;

import 'package:flutter/material.dart';

class JobbeesColors {
  JobbeesColors._();

  // ---- Primary palette (honey orange — logo-true) ----
  // Re-based on the logo's actual orange (#ED713E), a warmer/softer honey tone
  // than the old hot coral (#FF6B2C) which read as a "warning". Reads as warm +
  // premium, and is on-brand for the honeycomb mark (bees → honey).
  static const primary50 = Color(0xFFFDF3EC);
  static const primary100 = Color(0xFFFBE3D2);
  static const primary200 = Color(0xFFF6C5A0);
  static const primary300 = Color(0xFFF0A572);
  static const primary400 = Color(0xFFEE8B53);
  static const primary500 = Color(0xFFED713E); // main brand (logo orange)
  static const primary600 = Color(0xFFDB5E2C);
  static const primary700 = Color(0xFFB84A24);
  static const primary800 = Color(0xFF92391E);
  static const primary900 = Color(0xFF76301B);

  /// Default = primary-500
  static const primary = primary500;

  // ---- Dark palette (navy-charcoal) ----
  static const dark50 = Color(0xFFF5F5F7);
  static const dark100 = Color(0xFFE8E8ED);
  static const dark200 = Color(0xFFD1D1DB);
  static const dark300 = Color(0xFFA3A3B5);
  static const dark400 = Color(0xFF71718A);
  static const dark500 = Color(0xFF4A4A62);
  static const dark600 = Color(0xFF33334A);
  static const dark700 = Color(0xFF262640);
  static const dark800 = Color(0xFF1A1A2E); // main dark
  static const dark900 = Color(0xFF0F0F1D);

  /// Default = dark-800
  static const dark = dark800;

  // ---- Semantic colors ----
  static const success = Color(0xFF22C55E);
  static const successDark = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ---- Background surfaces ----
  static const bgScreenLight = Color(0xFFFFFFFF);
  static const bgScreenDark = dark900;
  static const bgCardLight = Color(0xFFFFFFFF);
  static const bgCardDark = dark800;
  static const bgInputLight = dark50;
  static const bgInputDark = dark700;
}

// ============================================================================
// ColorScheme — Light mode (the only mode shipped at MVP)
// ============================================================================
//
// Material 3 ColorScheme. Headlines + body get the proper foreground tokens
// from `JobbeesColors.dark` shades.

final lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: JobbeesColors.primary,
  onPrimary: Colors.white,
  primaryContainer: JobbeesColors.primary50,
  onPrimaryContainer: JobbeesColors.primary700,
  secondary: JobbeesColors.dark800,
  onSecondary: Colors.white,
  secondaryContainer: JobbeesColors.dark50,
  onSecondaryContainer: JobbeesColors.dark800,
  tertiary: JobbeesColors.info,
  onTertiary: Colors.white,
  error: JobbeesColors.error,
  onError: Colors.white,
  errorContainer: Color(0xFFFEE2E2),
  onErrorContainer: Color(0xFF991B1B),
  surface: JobbeesColors.bgCardLight,
  onSurface: JobbeesColors.dark800,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: JobbeesColors.dark50,
  surfaceContainer: JobbeesColors.dark50,
  surfaceContainerHigh: JobbeesColors.dark100,
  surfaceContainerHighest: JobbeesColors.dark200,
  onSurfaceVariant: JobbeesColors.dark400,
  outline: JobbeesColors.dark200,
  outlineVariant: JobbeesColors.dark100,
  shadow: Color(0x14000000), // 8% black
  scrim: Color(0x66000000), // 40% black for modal backdrops
  inverseSurface: JobbeesColors.dark800,
  onInverseSurface: Colors.white,
  inversePrimary: JobbeesColors.primary300,
);

// ============================================================================
// ColorScheme — Dark mode (defined but NOT shipped at MVP)
// ============================================================================
//
// Defined now so dark mode is one config flag away in year 2. See
// `docs/brand/UI-PRINCIPLES.md` for the strategy.

final darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(
    0xFFF4A06A,
  ), // lighter honey for AA contrast on dark surface
  onPrimary: JobbeesColors.dark900,
  primaryContainer: JobbeesColors.primary800,
  onPrimaryContainer: JobbeesColors.primary100,
  secondary: JobbeesColors.dark100,
  onSecondary: JobbeesColors.dark900,
  secondaryContainer: JobbeesColors.dark700,
  onSecondaryContainer: JobbeesColors.dark100,
  tertiary: const Color(0xFF60A5FA), // lighter info
  onTertiary: JobbeesColors.dark900,
  error: const Color(0xFFF87171), // lighter error
  onError: JobbeesColors.dark900,
  errorContainer: const Color(0xFF991B1B),
  onErrorContainer: const Color(0xFFFECACA),
  surface: JobbeesColors.bgCardDark,
  onSurface: JobbeesColors.dark100,
  surfaceContainerLowest: JobbeesColors.dark900,
  surfaceContainerLow: JobbeesColors.dark800,
  surfaceContainer: JobbeesColors.dark700,
  surfaceContainerHigh: JobbeesColors.dark600,
  surfaceContainerHighest: JobbeesColors.dark500,
  onSurfaceVariant: JobbeesColors.dark300,
  outline: JobbeesColors.dark500,
  outlineVariant: JobbeesColors.dark600,
  shadow: const Color(0x52000000), // 32% black
  scrim: const Color(0x99000000), // 60% black
  inverseSurface: JobbeesColors.dark100,
  onInverseSurface: JobbeesColors.dark800,
  inversePrimary: JobbeesColors.primary500,
);

// ============================================================================
// Gradients (use sparingly — hero moments only)
// ============================================================================

// Honey blend: logo orange → warm amber. Elegant + on-brand, not "warning".
// Hero moments only (icon containers, celebration) — it lightens, so it's NOT
// for surfaces with overlaid white text. Buttons use [gradientPrimaryButton].
const gradientPrimary = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [JobbeesColors.primary, Color(0xFFF4A24B)],
);

// Primary CTA fill — a "lit from above" treatment: a rich honey-gold → deep
// terracotta base (vertical) sitting under a faint white top sheen
// ([gradientButtonSheen]), for a glassy, tactile pill. The deep lower half keeps
// the centred white label legible. Buttons intentionally use a vertical fill (a
// top highlight reads as light from above), not the 135° hero diagonal.
const gradientPrimaryButton = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF6A24A), Color(0xFFD4541F)],
);

// The glassy top highlight layered over [gradientPrimaryButton] on primary CTAs
// (~30% white fading to transparent). Gives the button its lit-from-above sheen.
const gradientButtonSheen = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x4DFFFFFF), Color(0x00FFFFFF)],
);

const gradientSuccess = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [JobbeesColors.success, JobbeesColors.successDark],
);

const gradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [JobbeesColors.dark800, JobbeesColors.dark600],
);
