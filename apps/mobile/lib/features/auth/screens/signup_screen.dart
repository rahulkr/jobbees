// ignore_for_file: public_member_api_docs

/// Email/password signup (inventory row 2).
///
/// Creates a CLIENT/TASKER account against the Sprint 1 `/auth/signup` backend.
/// On success the [AuthController] flips the session to authenticated and the
/// router redirects home — this screen never navigates itself (CLAUDE.md rule
/// 5). Phone OTP, role selection, and Google/Apple sign-in are separate rows.
///
/// Four states (CLAUDE.md rule 3): content is the form; loading is the in-flight
/// submit (button spinner, inputs disabled); error renders inline (field-level
/// validation + a server-error banner). There is no async "empty" state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';

/// Mirrors the backend SignupDto password rule (`@MinLength(10)`).
const int _kMinPasswordLength = 10;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    // Pragmatic check — the API is the source of truth on email validity.
    final emailLooksValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    setState(() {
      _firstNameError = _firstName.text.trim().isEmpty
          ? 'Enter your first name'
          : null;
      _lastNameError = _lastName.text.trim().isEmpty
          ? 'Enter your last name'
          : null;
      _emailError = emailLooksValid ? null : 'Enter a valid email address';
      _passwordError = _password.text.length < _kMinPasswordLength
          ? 'Use at least $_kMinPasswordLength characters'
          : null;
    });
    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
          );
      // Success: the router redirect takes over. Nothing to navigate here.
    } on AppError catch (error) {
      if (mounted) setState(() => _formError = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          compact: (context) => _form(context, maxWidth: double.infinity),
          expanded: (context) => Center(child: _form(context, maxWidth: 480)),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, {required double maxWidth}) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JSpacing.lg),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: JSpacing.lg),
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: JSpacing.sm),
                Text(
                  'Join JOBBees to post jobs or earn as a tasker.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: JSpacing.xl),
                if (_formError != null) ...[
                  _ErrorBanner(message: _formError!),
                  const SizedBox(height: JSpacing.base),
                ],
                JTextField(
                  label: 'First name',
                  controller: _firstName,
                  enabled: !_submitting,
                  errorText: _firstNameError,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: JSpacing.base),
                JTextField(
                  label: 'Last name',
                  controller: _lastName,
                  enabled: !_submitting,
                  errorText: _lastNameError,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                ),
                const SizedBox(height: JSpacing.base),
                JTextField(
                  label: 'Email',
                  controller: _email,
                  enabled: !_submitting,
                  errorText: _emailError,
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: JSpacing.base),
                JTextField(
                  label: 'Password',
                  controller: _password,
                  enabled: !_submitting,
                  errorText: _passwordError,
                  helperText: 'At least $_kMinPasswordLength characters',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                  ),
                ),
                const SizedBox(height: JSpacing.xl),
                JButton.primary(
                  label: 'Create account',
                  onPressed: _submitting ? null : _submit,
                  loading: _submitting,
                  expanded: true,
                  size: JButtonSize.lg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(JSpacing.base),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: JRadius.buttonMdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: JSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
