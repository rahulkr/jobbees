/// JButton — the only button in the app.
///
/// Variants: primary / secondary / danger / ghost
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

import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';

enum JButtonVariant { primary, secondary, danger, ghost }

enum JButtonSize { sm, md, lg }

class JButton extends StatelessWidget {
  const JButton._({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.size = JButtonSize.md,
    this.icon,
    this.loading = false,
    this.expanded = false,
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
    Key? key,
  }) =>
      JButton._(
        label: label,
        onPressed: onPressed,
        variant: JButtonVariant.primary,
        size: size,
        icon: icon,
        loading: loading,
        expanded: expanded,
        key: key,
      );

  /// Secondary — neutral. Use for "not now", "back", lower-emphasis actions.
  factory JButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    bool loading = false,
    bool expanded = false,
    Key? key,
  }) =>
      JButton._(
        label: label,
        onPressed: onPressed,
        variant: JButtonVariant.secondary,
        size: size,
        icon: icon,
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
  }) =>
      JButton._(
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
  factory JButton.ghost({
    required String label,
    required VoidCallback? onPressed,
    JButtonSize size = JButtonSize.md,
    IconData? icon,
    bool loading = false,
    bool expanded = false,
    Key? key,
  }) =>
      JButton._(
        label: label,
        onPressed: onPressed,
        variant: JButtonVariant.ghost,
        size: size,
        icon: icon,
        loading: loading,
        expanded: expanded,
        key: key,
      );

  final String label;
  final VoidCallback? onPressed;
  final JButtonVariant variant;
  final JButtonSize size;
  final IconData? icon;
  final bool loading;

  /// If true, the button expands to fill its parent's width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null || loading;

    final (bg, fg, border) = switch (variant) {
      JButtonVariant.primary => (scheme.primary, scheme.onPrimary, Colors.transparent),
      JButtonVariant.secondary => (scheme.surfaceContainerHighest, scheme.onSurface, Colors.transparent),
      JButtonVariant.danger => (scheme.error, scheme.onError, Colors.transparent),
      JButtonVariant.ghost => (Colors.transparent, scheme.primary, Colors.transparent),
    };

    final (height, hPadding, fontSize) = switch (size) {
      JButtonSize.sm => (40.0, JSpacing.base, 14.0),
      JButtonSize.md => (52.0, JSpacing.lg, 16.0),
      JButtonSize.lg => (56.0, JSpacing.xl, 16.0),
    };

    final radius = size == JButtonSize.lg ? JRadius.buttonLgAll : JRadius.buttonMdAll;

    final button = Material(
      color: isDisabled ? bg.withValues(alpha: 0.4) : bg,
      borderRadius: radius,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: radius,
        splashFactory: InkSparkle.splashFactory,
        child: Container(
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
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: isDisabled ? fg.withValues(alpha: 0.6) : fg),
                const SizedBox(width: JSpacing.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? fg.withValues(alpha: 0.6) : fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
