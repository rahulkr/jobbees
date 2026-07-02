/// JSnackbar — brand-styled transient feedback via the Material 3 SnackBar.
///
/// Used for form-level outcomes that should not pop the layout: a failed
/// submit (with an optional Retry) and, by convention, success confirmations.
/// Styling (dark surface, white text, primary action, floating, rounded) comes
/// from `snackBarTheme` in app_theme, so callers only pass content.
///
/// Native `SnackBar` is announced by VoiceOver / TalkBack, so this keeps the
/// accessibility the old inline banner had. Per docs/brand UI-PRINCIPLES
/// § Snackbars: bottom, ~4s, primary-300 action.
library;

import 'package:flutter/material.dart';

class JSnackbar {
  JSnackbar._();

  /// Surfaces [message] as an error snackbar. When [onRetry] is given (only for
  /// transient failures — see [AppError.retryable]) it shows a Retry action and
  /// lingers longer so the action is reachable.
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    // One error at a time: replace any visible snackbar rather than queueing.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: onRetry == null
            ? const Duration(seconds: 4)
            : const Duration(seconds: 8),
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
  }

  /// Surfaces [message] as a success confirmation snackbar.
  /// Shorter than an error (~3s) — the user already knows what they did.
  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
