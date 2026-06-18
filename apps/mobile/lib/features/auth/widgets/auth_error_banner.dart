// ignore_for_file: public_member_api_docs

/// Inline error banner shared by the auth screens (signup/login) — renders a
/// server-side failure above the form (CLAUDE.md rule 8).
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

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
