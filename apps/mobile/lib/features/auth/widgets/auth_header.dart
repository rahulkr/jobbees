// ignore_for_file: public_member_api_docs

/// Branded header for the signed-out auth funnel (signup / login / role).
///
/// The JOBBees logo above the screen title + optional subtitle, so every auth
/// screen opens with a consistent, on-brand identity rather than a bare text
/// title.
library;

import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand lockup (honeycomb + JOBBEES wordmark) — the auth funnel opens
        // with both the recognisable mark and the brand name. It's a wide
        // asset, so pin the height and let the width follow its aspect.
        Image.asset(
          'assets/branding/wordmark.png',
          height: 40,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(height: JSpacing.lg),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: JSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
