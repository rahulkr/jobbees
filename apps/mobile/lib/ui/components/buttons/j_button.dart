/// JButton — the only button in the app.
///
/// Variants: primary / secondary / danger / ghost / apple
/// Sizes: sm / md / lg
/// States: idle / pressed / disabled / loading
///
/// Reference: docs/brand/UI-PRINCIPLES.md § Buttons + docs/brand/VOICE.md § CTAs.
///
/// Usage:
///   JButton.primary(label: 'Post a job', onPressed: () => ...)
///   JButton.danger(label: 'Yes, delete it', onPressed: () => ...)
///   JButton.secondary(label: 'I will do it later', onPressed: () => ...)
///   JButton.ghost(label: 'Skip', onPressed: () => ...)
///
/// With loading:
///   JButton.primary(label: 'Saving...', onPressed: null, loading: true)

library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/colors.dart';
import '../../platform/j_pressable.dart';
import '../../tokens/tokens.dart';

enum JButtonVariant { primary, secondary, danger, ghost, apple }

enum JButtonSize { sm, md, lg }

class JButton extends StatelessWidget {
  const JButton._({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.size = JButtonSize.md,
    this.icon,
    this.leading,
    this.loading = false,
    this.expanded = false,
    this.gradient = false,
    this.neutral = false,
    super.key,
  });

  /// Primary — high-emphasis. Use one per screen for the main action.
  factory JButton.primary({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    bool loading = false,
    bool expanded = false,
    bool gradient = true,
    Key? key,
  }) => JButton._(
    label: label,
    onPressed: onPressed,
    variant: JButtonVariant.primary,
    size: size,
    icon: icon,
    loading: loading,
    expanded: expanded,
    gradient: gradient,
    key: key,
  );

  /// Secondary — neutral. Use for "not now", "back", lower-emphasis actions.
  factory JButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    Widget? leading,
    bool loading = false,
    bool expanded = false,
    Key? key,
  }) => JButton._(
    label: label,
    onPressed: onPressed,
    variant: JButtonVariant.secondary,
    size: size,
    icon: icon,
    leading: leading,
    loading: loading,
    expanded: expanded,
    key: key,
  );

  /// Danger — destructive. Use for delete / cancel / withdraw.
  /// Label MUST restate the action per VOICE.md ("Yes, delete it" not "OK").
  factory JButton.danger({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    bool loading = false,
    bool expanded = false,
    Key? key,
  }) => JButton._(
    label: label,
    onPressed: onPressed,
    variant: JButtonVariant.danger,
    size: size,
    icon: icon,
    loading: loading,
    expanded: expanded,
    key: key,
  );

  /// Ghost — minimal. Text-only. Use for tertiary actions ("Skip", "Learn more").
  /// Pass [neutral] to render the label in a muted colour instead of coral, so
  /// the screen's coral budget stays with its one dominant accent (Charter § 2).
  factory JButton.ghost({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    bool loading = false,
    bool expanded = false,
    bool neutral = false,
    Key? key,
  }) => JButton._(
    label: label,
    onPressed: onPressed,
    variant: JButtonVariant.ghost,
    size: size,
    icon: icon,
    loading: loading,
    expanded: expanded,
    neutral: neutral,
    key: key,
  );

  /// Apple — the App Store-compliant "Sign in with Apple" button: black fill with
  /// a white label and Apple's official mark (pass it as [leading]). Follows
  /// Apple's HIG for building a custom Sign in with Apple button, and reuses all
  /// of JButton's chrome so it matches the Google button pixel-for-pixel.
  factory JButton.apple({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    Widget? leading,
    bool loading = false,
    bool expanded = false,
    Key? key,
  }) => JButton._(
    label: label,
    onPressed: onPressed,
    variant: JButtonVariant.apple,
    size: size,
    leading: leading,
    loading: loading,
    expanded: expanded,
    key: key,
  );

  final String label;
  final VoidCallback? onPressed;
  final JButtonVariant variant;
  final JButtonSize size;
  final IconData? icon;

  /// Custom leading widget (e.g. a brand logo image) shown before the label, in
  /// place of [icon]. Takes precedence over [icon] when both are provided.
  final Widget? leading;
  final bool loading;

  /// If true, the button expands to fill its parent's width.
  final bool expanded;

  /// If true (primary only), fills with the honey "depth" gradient instead of a
  /// flat colour. On by default for primary CTAs; pass `gradient: false` for a
  /// flat button. See docs/brand/COLORS.md § Gradients.
  final bool gradient;

  /// If true (ghost only), the label is muted (`onSurfaceVariant`) rather than
  /// coral — for a secondary link that shouldn't spend the screen's coral.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null || loading;

    final (bg, fg, border) = switch (variant) {
      JButtonVariant.primary => (
        scheme.primary,
        scheme.onPrimary,
        Colors.transparent,
      ),
      JButtonVariant.secondary => (
        // Clean outline (white fill + subtle border) so secondary actions —
        // e.g. social sign-in — recede and let the primary CTA dominate.
        scheme.surface,
        scheme.onSurface,
        scheme.outline,
      ),
      JButtonVariant.danger => (
        scheme.error,
        scheme.onError,
        Colors.transparent,
      ),
      JButtonVariant.ghost => (
        Colors.transparent,
        neutral ? scheme.onSurfaceVariant : scheme.primary,
        Colors.transparent,
      ),
      // Apple's HIG mandates the exact black button + white mark/label for Sign
      // in with Apple — a fixed brand requirement, so raw black/white (not a
      // theme token).
      JButtonVariant.apple => (Colors.black, Colors.white, Colors.transparent),
    };

    final (height, hPadding, fontSize) = switch (size) {
      JButtonSize.sm => (40.0, JSpacing.base, 14.0),
      JButtonSize.md => (52.0, JSpacing.lg, 16.0),
      JButtonSize.lg => (56.0, JSpacing.xl, 16.0),
    };

    final radius = size == JButtonSize.lg
        ? JRadius.buttonLgAll
        : JRadius.buttonMdAll;

    final content = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: variant == JButtonVariant.ghost
            ? null
            : Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDisabled ? fg.withValues(alpha: 0.6) : fg,
              ),
            ),
            const SizedBox(width: JSpacing.sm),
          ] else if (leading != null) ...[
            leading!,
            const SizedBox(width: JSpacing.sm),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isDisabled ? fg.withValues(alpha: 0.6) : fg,
            ),
            const SizedBox(width: JSpacing.sm),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isDisabled ? fg.withValues(alpha: 0.6) : fg,
            ),
          ),
        ],
      ),
    );

    final useGradient =
        gradient && variant == JButtonVariant.primary && !isDisabled;

    final material = Material(
      color: useGradient
          ? Colors.transparent
          : (isDisabled ? bg.withValues(alpha: 0.4) : bg),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: useGradient
          ? DecoratedBox(
              // Honey-gold base + a faint white top sheen layered over it —
              // a "lit from above", glassy pill. Label sits on top of both.
              decoration: const BoxDecoration(gradient: gradientPrimaryButton),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: gradientButtonSheen),
                child: content,
              ),
            )
          : content,
    );

    // The warm lift goes on an outer box (outside the Material's clip) so the
    // shadow isn't clipped. Only the raised primary CTA gets it.
    final button = JPressable(
      onTap: isDisabled ? null : onPressed,
      child: useGradient
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: JShadows.coralCta,
              ),
              child: material,
            )
          : material,
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
