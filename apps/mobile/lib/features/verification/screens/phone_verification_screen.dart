// ignore_for_file: public_member_api_docs

/// Phone OTP verification (inventory row 234).
///
/// Two steps in one screen: enter a phone number, then the 6-digit code we
/// "send" (dev accepts 000000). On success the server marks the account's phone
/// verified; we refetch the profile and pop back to the verification hub, which
/// re-renders from the updated session.
///
/// Tasker-only on the backend; reached from the hub, which only a tasker sees.
///
/// Design (per Design Quality Charter § OTP entry — Cash App / WhatsApp bar):
///   * 6 individually-focused boxes with auto-advance, haptic per digit, and
///     auto-submit on the 6th digit — replacing the generic single-field entry.
///   * Small hero mark at the top; staggered entrance on hero / body / input /
///     CTA so the screen unfolds rather than pops.
///   * On the code step, "Change number" is de-emphasised as a ghost — the
///     primary flow is entering the code, not going back.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/verification_providers.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _phoneFocus = FocusNode();

  bool _codeSent = false;
  bool _busy = false;
  String? _phoneError;
  String? _codeError;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String get _normalisedPhone => _phone.text.replaceAll(RegExp(r'\s+'), '');

  bool _validatePhone() {
    final ok = RegExp(r'^\+?[0-9]{8,15}$').hasMatch(_normalisedPhone);
    setState(() => _phoneError = ok ? null : 'Enter a valid phone number');
    return ok;
  }

  bool _validateCode() {
    final ok = RegExp(r'^[0-9]{6}$').hasMatch(_code.text.trim());
    setState(() => _codeError = ok ? null : 'Enter the 6-digit code');
    return ok;
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_validatePhone()) {
      JHaptics.error();
      _phoneFocus.requestFocus();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(phoneVerificationControllerProvider)
          .sendCode(_normalisedPhone);
      if (mounted) setState(() => _codeSent = true);
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        JSnackbar.showError(
          context,
          error.message,
          onRetry: error.retryable ? _sendCode : null,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_validateCode()) {
      JHaptics.error();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(phoneVerificationControllerProvider)
          .verifyCode(phone: _normalisedPhone, code: _code.text.trim());
      if (mounted) context.pop();
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        JSnackbar.showError(
          context,
          error.message,
          onRetry: error.retryable ? _verify : null,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeNumber() {
    setState(() {
      _codeSent = false;
      _code.clear();
      _codeError = null;
    });
  }

  /// Called each time the user finishes entering all 6 digits — auto-submit.
  void _onCodeCompleted(String code) {
    if (_busy) return;
    // Small delay so the last-digit haptic doesn't collide with the loading state.
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_busy) _verify();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JAppBar(
        title: _codeSent ? 'Enter the code' : 'Verify your phone',
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(context, maxWidth: double.infinity),
          expanded: (context) => Center(child: _body(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, {required double maxWidth}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        // KEY on step so entrance re-plays when we transition phone → code.
        child: SingleChildScrollView(
          key: ValueKey(_codeSent ? 'code-step' : 'phone-step'),
          padding: const EdgeInsets.all(JSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: JSpacing.sm),
              JEntrance(
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: JRadius.heroAll,
                    ),
                    child: Icon(
                      _codeSent
                          ? LucideIcons.messageSquare
                          : LucideIcons.smartphone,
                      size: 32,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.lg),
              JEntrance(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  _codeSent
                      ? 'Enter the 6-digit code we sent to $_normalisedPhone.'
                      : "We'll text you a 6-digit code to confirm your number.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: JSpacing.xl),
              if (!_codeSent) ..._phoneStep() else ..._codeStep(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneStep() => [
    JEntrance(
      delay: const Duration(milliseconds: 160),
      child: JTextField(
        label: 'Phone number',
        controller: _phone,
        focusNode: _phoneFocus,
        enabled: !_busy,
        errorText: _phoneError,
        hintText: '+61400000000',
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumber],
        onSubmitted: (_) => _sendCode(),
      ),
    ),
    const SizedBox(height: JSpacing.xl),
    JEntrance(
      delay: const Duration(milliseconds: 240),
      child: JButton.primary(
        label: 'Send code',
        onPressed: _busy ? null : _sendCode,
        loading: _busy,
        expanded: true,
        size: JButtonSize.lg,
      ),
    ),
  ];

  List<Widget> _codeStep() => [
    JEntrance(
      delay: const Duration(milliseconds: 160),
      child: JOtpField(
        controller: _code,
        onCompleted: _onCodeCompleted,
        enabled: !_busy,
        errorText: _codeError,
      ),
    ),
    const SizedBox(height: JSpacing.xl),
    JEntrance(
      delay: const Duration(milliseconds: 240),
      child: JButton.primary(
        label: 'Verify',
        onPressed: _busy ? null : _verify,
        loading: _busy,
        expanded: true,
        size: JButtonSize.lg,
      ),
    ),
    const SizedBox(height: JSpacing.sm),
    JEntrance(
      delay: const Duration(milliseconds: 300),
      child: JButton.ghost(
        label: 'Resend code',
        onPressed: _busy ? null : _sendCode,
        expanded: true,
      ),
    ),
    JEntrance(
      delay: const Duration(milliseconds: 340),
      child: JButton.ghost(
        label: 'Change number',
        onPressed: _busy ? null : _changeNumber,
        expanded: true,
      ),
    ),
  ];
}
