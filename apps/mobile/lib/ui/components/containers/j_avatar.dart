// ignore_for_file: public_member_api_docs

/// JAvatar — a circular user avatar with an initials fallback.
///
/// One consistent spec (honey `primaryContainer` circle + `onPrimaryContainer`
/// initials) so every profile surface renders the same avatar rather than
/// drifting per screen.
library;

import 'package:flutter/material.dart';

class JAvatar extends StatelessWidget {
  const JAvatar({required this.initials, this.size = 48, super.key});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
