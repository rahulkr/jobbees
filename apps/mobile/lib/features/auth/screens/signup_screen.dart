// ignore_for_file: public_member_api_docs

/// Email/password signup (inventory row 2).
///
/// Creates a CLIENT account against the Sprint 1 `/auth/signup` backend —
/// everyone signs up as a client and upgrades to a tasker later from the
/// profile screen (client note #4). On success the [AuthController] flips the
/// session to authenticated and the router redirects home — this screen never
/// navigates itself (CLAUDE.md rule 5). Phone OTP and Google/Apple sign-in are
/// separate rows.
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
import '../providers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_auth_buttons.dart';

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

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;

  bool _submitting = false;
  bool _obscurePassword = true;

  /// Progressive disclosure: the email form stays collapsed behind a "Sign up
  /// with email" action until the user opts in — keeps the first paint clean
  /// and stops the primary "Create account" CTA being pushed below the fold.
  bool _showEmailForm = false;

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

    setState(() => _submitting = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
          );
      // The router redirect takes over once the session flips. Nothing to
      // navigate here.
    } on AppError catch (error) {
      if (mounted) {
        JHaptics.error();
        JSnackbar.showError(
          context,
          error.message,
          onRetry: error.retryable ? _submit : null,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DismissKeyboard(
        child: SafeArea(
          child: ResponsiveLayout(
            compact: (context) => _form(context, maxWidth: double.infinity),
            expanded: (context) => Center(child: _form(context, maxWidth: 480)),
          ),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: JSpacing.lg),
                const JEntrance(
                  child: AuthHeader(
                    title: 'Create your account',
                    subtitle: 'Join JOBBees to post jobs or earn as a tasker.',
                  ),
                ),
                const SizedBox(height: JSpacing.xl),
                // Progressive disclosure — best practice for a social-dominant
                // signup (client note #5): Google/Apple lead; the email form stays
                // collapsed behind a "Sign up with email" action so the first paint
                // is clean and the primary "Create account" CTA is never pushed
                // below the fold (it appears, with its button, only when chosen).
                JEntrance(
                  delay: const Duration(milliseconds: 90),
                  child: SocialAuthButtons(
                    dividerAtBottom: true,
                    dividerLabel: _showEmailForm
                        ? 'or sign up with email'
                        : 'or',
                    onError: (message) {
                      if (message.isNotEmpty && mounted) {
                        JSnackbar.showError(context, message);
                      }
                    },
                  ),
                ),
                const SizedBox(height: JSpacing.lg),
                // Collapsed shows a "Sign up with email" button; expanded swaps
                // in the full form (ending in its own CTA). The size change
                // animates so the reveal reads as intentional, not a jump.
                JEntrance(
                  delay: const Duration(milliseconds: 160),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _showEmailForm ? _emailForm() : _emailTrigger(),
                  ),
                ),
                const SizedBox(height: JSpacing.lg),
                JEntrance(
                  delay: const Duration(milliseconds: 230),
                  child: Row(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reveals the email form and lands focus on the first field once it mounts.
  void _revealEmailForm() {
    setState(() => _showEmailForm = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstNameFocus.requestFocus();
    });
  }

  /// Collapsed state: a single action that opts the user into email signup.
  Widget _emailTrigger() {
    return JButton.secondary(
      label: 'Sign up with email',
      icon: LucideIcons.mail,
      onPressed: _submitting ? null : _revealEmailForm,
      expanded: true,
      size: JButtonSize.lg,
    );
  }

  /// Expanded state: the full email form, ending in its own "Create account" CTA
  /// so the primary action is always in view once the form is shown.
  Widget _emailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First + last name share a row to keep the form compact.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: JTextField(
                label: 'First name',
                controller: _firstName,
                focusNode: _firstNameFocus,
                enabled: !_submitting,
                errorText: _firstNameError,
                hintText: 'Jordan',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
              ),
            ),
            const SizedBox(width: JSpacing.base),
            Expanded(
              child: JTextField(
                label: 'Last name',
                controller: _lastName,
                focusNode: _lastNameFocus,
                enabled: !_submitting,
                errorText: _lastNameError,
                hintText: 'Lee',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
              ),
            ),
          ],
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
          suffixIcon: JPressable(
            onTap: _submitting
                ? null
                : () => setState(() => _obscurePassword = !_obscurePassword),
            haptic: false,
            child: Padding(
              padding: const EdgeInsets.all(JSpacing.sm),
              child: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
    );
  }
}
