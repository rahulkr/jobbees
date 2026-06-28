// ignore_for_file: public_member_api_docs

/// Reset password (inventory row 10, completion step).
///
/// Reached from the reset email link (`/auth/reset?token=...`). Takes a new
/// password and submits it with the token. On success the user is sent back to
/// login to sign in with the new password (we don't auto-login from a reset).
/// A missing/blank token renders an invalid-link state instead of the form.
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

/// Matches the backend ResetPasswordDto (`@MinLength(10)`).
const int _kMinPasswordLength = 10;

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.token, super.key});

  /// Token from the reset email link; null/empty renders the invalid state.
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _passwordError;
  String? _confirmError;
  bool _submitting = false;
  bool _obscure = true;
  bool _done = false;

  bool get _hasToken => (widget.token ?? '').isNotEmpty;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _passwordError = _password.text.length < _kMinPasswordLength
          ? 'Use at least $_kMinPasswordLength characters'
          : null;
      _confirmError = _confirm.text != _password.text
          ? 'Passwords do not match'
          : null;
    });
    return _passwordError == null && _confirmError == null;
  }

  void _focusFirstError() {
    final target = _passwordError != null
        ? _passwordFocus
        : _confirmError != null
        ? _confirmFocus
        : null;
    target?.requestFocus();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      JHaptics.error();
      _focusFirstError();
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: widget.token!, newPassword: _password.text);
      if (mounted) setState(() => _done = true);
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
    final Widget content;
    if (!_hasToken) {
      content = _invalidLink(context);
    } else if (_done) {
      content = _success(context);
    } else {
      content = _form(context);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: content,
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: JSpacing.lg),
        const AuthHeader(
          title: 'Choose a new password',
          subtitle: 'Pick a password you have not used before.',
        ),
        const SizedBox(height: JSpacing.xl),
        JTextField(
          label: 'New password',
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !_submitting,
          errorText: _passwordError,
          helperText: 'At least $_kMinPasswordLength characters',
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          suffixIcon: IconButton(
            onPressed: _submitting
                ? null
                : () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff),
            tooltip: _obscure ? 'Show password' : 'Hide password',
          ),
        ),
        const SizedBox(height: JSpacing.base),
        JTextField(
          label: 'Confirm password',
          controller: _confirm,
          focusNode: _confirmFocus,
          enabled: !_submitting,
          errorText: _confirmError,
          helperText: 'Type it again',
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: JSpacing.xl),
        JButton.primary(
          label: 'Update password',
          onPressed: _submitting ? null : _submit,
          loading: _submitting,
          expanded: true,
          size: JButtonSize.lg,
        ),
      ],
    );
  }

  Widget _success(BuildContext context) => _Notice(
    icon: LucideIcons.circleCheck,
    title: 'Password updated',
    body: 'Log in with your new password.',
    cta: 'Log in',
    onCta: () => context.go('/auth/login'),
  );

  Widget _invalidLink(BuildContext context) => _Notice(
    icon: LucideIcons.unlink,
    title: 'This link has expired',
    body: 'Reset links are single-use and time-limited. Request a new one.',
    cta: 'Request a new link',
    onCta: () => context.go('/auth/forgot'),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.onCta,
  });

  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
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
          child: Icon(icon, size: 36, color: scheme.primary),
        ),
        const SizedBox(height: JSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: JSpacing.sm),
        Text(
          body,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: JSpacing.xl),
        JButton.primary(
          label: cta,
          onPressed: onCta,
          expanded: true,
          size: JButtonSize.lg,
        ),
      ],
    );
  }
}
