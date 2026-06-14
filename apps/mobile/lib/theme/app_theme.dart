// ignore_for_file: public_member_api_docs

/// JOBBees Flutter theme.
///
/// Material 3 (`useMaterial3: true`), Inter font via google_fonts,
/// generous border radius, JOBBees brand palette.
///
/// See `docs/brand/UI-PRINCIPLES.md` for the design philosophy and
/// `docs/brand/COLORS.md` for color usage rules.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class JobbeesTheme {
  JobbeesTheme._();

  static ThemeData light() => _buildTheme(lightColorScheme, Brightness.light);
  static ThemeData dark() => _buildTheme(darkColorScheme, Brightness.dark);

  static ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final textTheme = _buildTextTheme(scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          brightness == Brightness.light
              ? JobbeesColors.bgScreenLight
              : JobbeesColors.bgScreenDark,
      textTheme: textTheme,

      // Generous corners everywhere
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Primary CTAs: filled, large, 56px tall
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Secondary CTAs: outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(color: scheme.outline, width: 2),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons (used for "Forgot password?" etc.)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields: 56px, dark-50 background, transparent border → primary on focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            brightness == Brightness.light
                ? JobbeesColors.bgInputLight
                : JobbeesColors.bgInputDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: JobbeesColors.dark300,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.error,
        ),
      ),

      // Chips (categories, filters)
      chipTheme: ChipThemeData(
        backgroundColor:
            brightness == Brightness.light
                ? JobbeesColors.dark50
                : JobbeesColors.dark700,
        selectedColor: scheme.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: scheme.onPrimary,
        ),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Bottom nav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
            color:
                states.contains(WidgetState.selected)
                    ? scheme.primary
                    : JobbeesColors.dark600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color:
                states.contains(WidgetState.selected)
                    ? scheme.primary
                    : JobbeesColors.dark400,
            size: 24,
          );
        }),
        elevation: 0,
      ),

      // FAB (the raised "Post a job" button)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Snackbar (used for non-modal feedback)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: JobbeesColors.dark800,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        actionTextColor: JobbeesColors.primary300,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Bottom sheets (used for "Sign up to publish" etc.)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dialogs (use sparingly — prefer bottom sheets on mobile)
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color:
            brightness == Brightness.light
                ? JobbeesColors.dark100
                : JobbeesColors.dark700,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: 24,
      ),

      // App bar (used minimally — most screens have custom top bars)
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),
    );
  }

  // Inter typography — Material 3 type scale
  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: baseColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: baseColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: baseColor,
      ),
    );
  }
}

// ============================================================================
// Spacing tokens (8pt grid)
// ============================================================================

class JobbeesSpacing {
  JobbeesSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// ============================================================================
// Shape tokens
// ============================================================================

class JobbeesShapes {
  JobbeesShapes._();

  static const chip = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const buttonMd = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const buttonLg = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  static const card = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  static const hero = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(32)),
  );
}

// ============================================================================
// Motion tokens
// ============================================================================

class JobbeesMotion {
  JobbeesMotion._();

  static const fast = Duration(milliseconds: 100);
  static const normal = Duration(milliseconds: 250);
  static const sheet = Duration(milliseconds: 300);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;
  static const sheetCurve = Cubic(0.16, 1, 0.3, 1); // smooth, slightly bouncy
}
