// ignore_for_file: public_member_api_docs

/// Centred status panel for auth outcomes (verified / link expired / etc):
/// a hero icon, title, body, and a single primary action. Keeps the
/// confirmation/terminal states across the auth funnel visually consistent.
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Colour tone for the hero mark. [error] makes a failure state (e.g. an
/// expired link) read as an error rather than sharing the success chrome.
enum AuthNoticeTone { brand, error }

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    this.tone = AuthNoticeTone.brand,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;
  final AuthNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: JSpacing.xxl),
        JHeroMark(
          icon: icon,
          tone: tone == AuthNoticeTone.error
              ? JHeroTone.error
              : JHeroTone.brand,
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
