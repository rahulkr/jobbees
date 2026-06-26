// ignore_for_file: public_member_api_docs

/// Forgot password (inventory row 10, request step).
///
/// Collects an email and asks the API to send a reset link. The backend always
/// returns success (it never reveals whether an account exists), so a
/// successful call always lands on the same "check your email" confirmation.
/// The reset step itself is [ResetPasswordScreen], reached from the email link.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_header.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _emailFocus = FocusNode();

  String? _emailError;
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    final looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(
      () => _emailError = looksValid ? null : 'Enter a valid email address',
    );
    return _emailError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      JHaptics.error();
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        final mapped = ErrorMapper.map(error);
        JHaptics.error();
        JSnackbar.showError(
          context,
          mapped.message,
          onRetry: mapped.retryable ? _submit : null,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _body(context, maxWidth: double.infinity),
          expanded: (context) => Center(child: _body(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, {required double maxWidth}) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: _sent ? _confirmation(context) : _form(context),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: JSpacing.lg),
          const AuthHeader(
            title: 'Reset your password',
            subtitle: "Enter your email and we'll send you a reset link.",
          ),
          const SizedBox(height: JSpacing.xl),
          JTextField(
            label: 'Email',
            controller: _email,
            focusNode: _emailFocus,
            enabled: !_submitting,
            errorText: _emailError,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: JSpacing.xl),
          JButton.primary(
            label: 'Send reset link',
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
            expanded: true,
            size: JButtonSize.lg,
          ),
          const SizedBox(height: JSpacing.sm),
          JButton.ghost(
            label: 'Back to login',
            onPressed: _submitting ? null : () => context.go('/auth/login'),
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _confirmation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: JSpacing.xxl),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: JRadius.heroAll,
          ),
          child: Icon(LucideIcons.mailCheck, size: 36, color: scheme.primary),
        ),
        const SizedBox(height: JSpacing.lg),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: JSpacing.sm),
        Text(
          "If an account exists for ${_email.text.trim()}, we've sent a link to "
          'reset your password.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: JSpacing.xl),
        JButton.primary(
          label: 'Back to login',
          onPressed: () => context.go('/auth/login'),
          expanded: true,
          size: JButtonSize.lg,
        ),
      ],
    );
  }
}
