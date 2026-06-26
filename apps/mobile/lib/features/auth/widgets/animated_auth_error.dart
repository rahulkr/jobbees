// ignore_for_file: public_member_api_docs

/// Animated, collapsible wrapper around [AuthErrorBanner] for the auth forms.
///
/// Pass the current form error, or null to hide it. When a message appears the
/// banner fades and grows in; when it clears it collapses away, so a server
/// error never pops the layout. Honours reduced-motion (instant, no animation)
/// per the brand motion rules. Pair with `JHaptics.error()` + focus-to-first
/// -error on submit for the full failed-submit feedback.
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import 'auth_error_banner.dart';

class AnimatedAuthError extends StatelessWidget {
  const AnimatedAuthError({required this.message, super.key});

  /// The server-side error to surface, or null to collapse the banner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : JMotion.snackbar;
    return AnimatedSize(
      duration: duration,
      curve: JMotion.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: JMotion.easeOut,
        switchOutCurve: JMotion.easeOut,
        child: message == null
            // Full width so the column's stretch width does not jump as the
            // banner animates in and out.
            ? const SizedBox(width: double.infinity)
            : Padding(
                // Keyed by text so a changed message cross-fades, not snaps.
                key: ValueKey<String>(message),
                padding: const EdgeInsets.only(bottom: JSpacing.base),
                child: AuthErrorBanner(message: message),
              ),
      ),
    );
  }
}
