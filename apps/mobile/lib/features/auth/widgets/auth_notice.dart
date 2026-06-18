// ignore_for_file: public_member_api_docs

/// Centred status panel for auth outcomes (verified / link expired / etc):
/// a hero icon, title, body, and a single primary action. Keeps the
/// confirmation/terminal states across the auth funnel visually consistent.
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
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
          label: ctaLabel,
          onPressed: onCta,
          expanded: true,
          size: JButtonSize.lg,
        ),
      ],
    );
  }
}
