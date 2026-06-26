// ignore_for_file: public_member_api_docs

/// Phone OTP verification (inventory row 234).
///
/// Two steps in one screen: enter a phone number, then the 6-digit code we
/// "send" (dev accepts 000000). On success the server marks the account's phone
/// verified; we refetch the profile and pop back to the verification hub, which
/// re-renders from the updated session.
///
/// Tasker-only on the backend; reached from the hub, which only a tasker sees.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _codeFocus = FocusNode();

  bool _codeSent = false;
  bool _busy = false;
  String? _phoneError;
  String? _codeError;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
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
      _codeFocus.requestFocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_codeSent ? 'Enter the code' : 'Verify your phone'),
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: JSpacing.sm),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code we sent to $_normalisedPhone.'
                    : "We'll text you a 6-digit code to confirm your number.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
    JTextField(
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
    const SizedBox(height: JSpacing.xl),
    JButton.primary(
      label: 'Send code',
      onPressed: _busy ? null : _sendCode,
      loading: _busy,
      expanded: true,
      size: JButtonSize.lg,
    ),
  ];

  List<Widget> _codeStep() => [
    JTextField(
      label: 'Verification code',
      controller: _code,
      focusNode: _codeFocus,
      enabled: !_busy,
      errorText: _codeError,
      hintText: '6-digit code',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 6,
      // iOS Smart Auth / Android SMS Retriever (apps/mobile CLAUDE.md rule 9).
      autofillHints: const [AutofillHints.oneTimeCode],
      onSubmitted: (_) => _verify(),
    ),
    const SizedBox(height: JSpacing.xl),
    JButton.primary(
      label: 'Verify',
      onPressed: _busy ? null : _verify,
      loading: _busy,
      expanded: true,
      size: JButtonSize.lg,
    ),
    const SizedBox(height: JSpacing.sm),
    JButton.ghost(
      label: 'Resend code',
      onPressed: _busy ? null : _sendCode,
      expanded: true,
    ),
    JButton.ghost(
      label: 'Change number',
      onPressed: _busy ? null : _changeNumber,
      expanded: true,
    ),
  ];
}
