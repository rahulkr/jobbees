/// JOtpField — dedicated 6-box OTP entry (Cash App / WhatsApp / iMessage bar).
///
/// Six individually-focused boxes, auto-advance on digit, haptic per digit,
/// auto-submit on completion, paste handling (paste a 6-digit code and every
/// box fills at once). Backspace on an empty box moves focus left.
///
/// This is the OTP interaction the Design Quality Charter names as the phone-
/// verification "signature detail" — replacing the generic single-field entry.
///
/// Usage:
///   JOtpField(
///     length: 6,
///     controller: _codeController,
///     onCompleted: (code) => _verify(code),
///     enabled: !_submitting,
///     errorText: _codeError,
///   )
///
/// The [controller]'s text is kept in sync — read it via `.text` to submit.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../platform/j_haptics.dart';
import '../../tokens/tokens.dart';

class JOtpField extends StatefulWidget {
  const JOtpField({
    required this.controller,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.errorText,
    this.autofocus = true,
    super.key,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final String? errorText;
  final bool autofocus;

  @override
  State<JOtpField> createState() => _JOtpFieldState();
}

class _JOtpFieldState extends State<JOtpField> {
  late final List<TextEditingController> _boxes = List.generate(
    widget.length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focus = List.generate(
    widget.length,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    // Keep local boxes in sync when the external controller is programmatically cleared.
    widget.controller.addListener(_syncFromExternal);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) _focus[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromExternal);
    for (final c in _boxes) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncFromExternal() {
    if (widget.controller.text.isEmpty && _joined().isNotEmpty) {
      for (final b in _boxes) {
        b.clear();
      }
      if (widget.enabled && mounted) _focus[0].requestFocus();
    }
  }

  String _joined() => _boxes.map((c) => c.text).join();

  void _emitChange() {
    final joined = _joined();
    if (widget.controller.text != joined) widget.controller.text = joined;
    widget.onChanged?.call(joined);
    if (joined.length == widget.length) {
      widget.onCompleted?.call(joined);
    }
  }

  void _onBoxChanged(int i, String value) {
    // Handle paste — many keyboards deliver the full string into one box.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < widget.length; j++) {
        _boxes[j].text = j < digits.length ? digits[j] : '';
      }
      final nextEmpty = digits.length >= widget.length
          ? widget.length - 1
          : digits.length;
      _focus[nextEmpty].requestFocus();
      JHaptics.selection();
      _emitChange();
      return;
    }
    if (value.isNotEmpty) {
      JHaptics.selection();
      if (i < widget.length - 1) {
        _focus[i + 1].requestFocus();
      } else {
        _focus[i].unfocus();
      }
    }
    _emitChange();
  }

  KeyEventResult _onKey(int i, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _boxes[i].text.isEmpty &&
        i > 0) {
      _focus[i - 1].requestFocus();
      _boxes[i - 1].clear();
      _emitChange();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < widget.length; i++)
              _OtpBox(
                controller: _boxes[i],
                focusNode: _focus[i],
                enabled: widget.enabled,
                hasError: hasError,
                onChanged: (v) => _onBoxChanged(i, v),
                onKey: (event) => _onKey(i, event),
                // Only the first box accepts the OS OTP autofill payload;
                // the paste-splitter above fans it out across siblings.
                autofillHints: i == 0
                    ? const [AutofillHints.oneTimeCode]
                    : null,
              ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: JSpacing.sm),
          Text(
            widget.errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onKey,
    this.autofillHints,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKey;
  final Iterable<String>? autofillHints;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.hasError ? scheme.error : scheme.primary;
    // Unfocused cells get a subtle hairline for definition; focused/error cells
    // get the accent. (Previously unfocused was transparent, so the only edge
    // was the fill.)
    final borderColor = _focused || widget.hasError
        ? accent
        : scheme.outlineVariant;

    return SizedBox(
      width: 48,
      height: 60,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: widget.onKey,
        child: AnimatedContainer(
          duration: JMotion.pressFeedback,
          curve: JMotion.easeOut,
          decoration: BoxDecoration(
            color: widget.enabled
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainer,
            borderRadius: JRadius.buttonMdAll,
            border: Border.all(color: borderColor, width: _focused ? 2 : 1.5),
            // Soft focus glow — a diffuse halo. The old blurRadius:0/spread:3
            // painted a hard second outline, reading as a doubled/nested box.
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: widget.autofillHints,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: scheme.onSurface),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLength: 1,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
