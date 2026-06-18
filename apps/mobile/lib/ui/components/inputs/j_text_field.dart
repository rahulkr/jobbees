/// JTextField — the standard single-line input.
///
/// Has a label above, helper or error text below.
/// 56px tall, brand corner radius, focus state in primary color.
///
/// Usage:
///   JTextField(
///     label: 'Email',
///     controller: emailController,
///     hintText: 'you@example.com',
///     keyboardType: TextInputType.emailAddress,
///   )
///
/// With error:
///   JTextField(
///     label: 'Email',
///     controller: emailController,
///     errorText: 'This email is already in use',
///   )

library;

import 'package:flutter/material.dart';
import '../../tokens/tokens.dart';

class JTextField extends StatefulWidget {
  const JTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<JTextField> createState() => _JTextFieldState();
}

class _JTextFieldState extends State<JTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? scheme.error
        : _focused
        ? scheme.primary
        : scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: JSpacing.xs),

        // Field
        AnimatedContainer(
          duration: JMotion.pressFeedback,
          curve: JMotion.easeOut,
          height: 56,
          decoration: BoxDecoration(
            // Light, calm input fill (dark-50) per docs/brand UI-PRINCIPLES
            // § Forms; a hairline outline gives definition, primary on focus.
            color: widget.enabled
                ? scheme.surfaceContainerLow
                : scheme.surfaceContainerHigh,
            borderRadius: JRadius.buttonMdAll,
            // Single, clean border: hairline at rest, 2px primary on focus.
            // No glow/shadow — it reads as a double outline.
            border: Border.all(color: borderColor, width: _focused ? 2 : 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: JSpacing.base),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _focused ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: JSpacing.md),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  maxLength: widget.maxLength,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(fontSize: 16, color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                    // Null EVERY border slot: the global inputDecorationTheme
                    // defines focused/enabled/error borders, and leaving them
                    // unset lets the theme draw a second ring on top of this
                    // widget's own border. The field's border is the
                    // AnimatedContainer above.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isCollapsed: true,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.suffixIcon != null) ...[
                const SizedBox(width: JSpacing.sm),
                widget.suffixIcon!,
              ],
            ],
          ),
        ),

        // Helper / error text
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: JSpacing.xs),
          Text(
            widget.errorText ?? widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: hasError ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
