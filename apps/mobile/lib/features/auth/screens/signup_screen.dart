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
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../ui/ui.dart';
import '../models/auth_models.dart';
import '../providers/auth_controller.dart';
import '../widgets/animated_auth_error.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_auth_buttons.dart';

/// Mirrors the backend SignupDto password rule (`@MinLength(10)`).
const int _kMinPasswordLength = 10;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({this.role, super.key});

  /// Chosen on the role-selection screen and carried through signup. Null means
  /// "decide later" — the backend defaults to CLIENT.
  final UserRole? role;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

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
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  /// Lands the cursor on the first field with an error so a failed submit
  /// points the user straight at the problem instead of leaving focus dropped.
  void _focusFirstError() {
    final target = _firstNameError != null
        ? _firstNameFocus
        : _lastNameError != null
        ? _lastNameFocus
        : _emailError != null
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
          .signUp(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            role: widget.role,
          );
      // Tasker-intent signups go straight to verification (the work side needs
      // it); clients fall through to the router redirect → home.
      if (mounted && widget.role == UserRole.tasker) context.go('/verify');
      // Otherwise the router redirect takes over. Nothing to navigate here.
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
                  title: 'Create your account',
                  subtitle: 'Join JOBBees to post jobs or earn as a tasker.',
                ),
                if (widget.role != null) ...[
                  const SizedBox(height: JSpacing.base),
                  _RoleChip(role: widget.role!),
                ],
                const SizedBox(height: JSpacing.xl),
                AnimatedAuthError(message: _formError),
                JTextField(
                  label: 'First name',
                  controller: _firstName,
                  focusNode: _firstNameFocus,
                  enabled: !_submitting,
                  errorText: _firstNameError,
                  hintText: 'Jordan',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: JSpacing.base),
                JTextField(
                  label: 'Last name',
                  controller: _lastName,
                  focusNode: _lastNameFocus,
                  enabled: !_submitting,
                  errorText: _lastNameError,
                  hintText: 'Lee',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                ),
                const SizedBox(height: JSpacing.base),
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
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
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
                const SizedBox(height: JSpacing.lg),
                SocialAuthButtons(
                  role: widget.role,
                  onError: (message) => setState(
                    () => _formError = message.isEmpty ? null : message,
                  ),
                ),
                const SizedBox(height: JSpacing.base),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    JButton.ghost(
                      label: 'Log in',
                      onPressed: _submitting
                          ? null
                          : () => context.go('/auth/login'),
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

/// Shows which role the account is being created as, with a quick way back to
/// the role picker to change it.
class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTasker = role == UserRole.tasker;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        JSpacing.md,
        JSpacing.sm,
        JSpacing.sm,
        JSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: JRadius.chipAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTasker ? LucideIcons.hammer : LucideIcons.clipboardList,
            size: 16,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: JSpacing.sm),
          Text(
            isTasker ? 'Signing up as a tasker' : 'Signing up as a client',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: JSpacing.xs),
          JButton.ghost(
            label: 'Change',
            onPressed: () => context.go('/auth/role'),
            size: JButtonSize.sm,
          ),
        ],
      ),
    );
  }
}
