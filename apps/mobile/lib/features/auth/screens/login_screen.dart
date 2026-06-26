// ignore_for_file: public_member_api_docs

/// Email/password login (inventory row 5).
///
/// Authenticates against the Sprint 1 `/auth/login` backend, reusing the
/// session foundation from the signup PR. On success [AuthController] flips the
/// session and the router redirects home — this screen never navigates itself
/// (CLAUDE.md rule 5). Biometric re-login (row 9), forgot-password (row 10) and
/// Google/Apple (rows 6/7) are separate rows.
///
/// Four states (rule 3): content is the form; loading is the in-flight submit;
/// error renders inline (field validation + a server-error banner). No async
/// "empty" state.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../providers/auth_controller.dart';
import '../widgets/animated_auth_error.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _formError;

  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    final emailLooksValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    setState(() {
      _emailError = emailLooksValid ? null : 'Enter a valid email address';
      _passwordError = _password.text.isEmpty ? 'Enter your password' : null;
    });
    return _emailError == null && _passwordError == null;
  }

  void _focusFirstError() {
    final target = _emailError != null
        ? _emailFocus
        : _passwordError != null
        ? _passwordFocus
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

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
      // Success: the router redirect takes over.
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        setState(() => _formError = error.message);
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
                const AuthHeader(
                  title: 'Welcome back',
                  subtitle: 'Log in to continue.',
                ),
                const SizedBox(height: JSpacing.xl),
                AnimatedAuthError(message: _formError),
                JTextField(
                  label: 'Email',
                  controller: _email,
                  focusNode: _emailFocus,
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
                  focusNode: _passwordFocus,
                  enabled: !_submitting,
                  errorText: _passwordError,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    ),
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                  ),
                ),
                const SizedBox(height: JSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: JButton.ghost(
                    label: 'Forgot password?',
                    onPressed: _submitting
                        ? null
                        : () => context.go('/auth/forgot'),
                    size: JButtonSize.sm,
                  ),
                ),
                const SizedBox(height: JSpacing.base),
                JButton.primary(
                  label: 'Log in',
                  onPressed: _submitting ? null : _submit,
                  loading: _submitting,
                  expanded: true,
                  size: JButtonSize.lg,
                ),
                const SizedBox(height: JSpacing.lg),
                SocialAuthButtons(
                  onError: (message) => setState(
                    () => _formError = message.isEmpty ? null : message,
                  ),
                ),
                const SizedBox(height: JSpacing.base),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    JButton.ghost(
                      label: 'Sign up',
                      onPressed: _submitting
                          ? null
                          : () => context.go('/auth/role'),
                      size: JButtonSize.sm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
