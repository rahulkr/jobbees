// ignore_for_file: public_member_api_docs

/// JHeroMark — the standard "icon in a soft rounded container" hero used at the
/// top of focused screens (auth, verification, terminal states). One size +
/// tone system so the app's signature mark is consistent instead of hand-rolled
/// at a different size on every screen.
library;

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../tokens/tokens.dart';

enum JHeroTone { brand, error, success }

class JHeroMark extends StatelessWidget {
  const JHeroMark({
    required this.icon,
    this.tone = JHeroTone.brand,
    this.size = 80,
    super.key,
  });

  final IconData icon;
  final JHeroTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (tone) {
      JHeroTone.brand => (scheme.primaryContainer, scheme.primary),
      JHeroTone.error => (scheme.errorContainer, scheme.error),
      JHeroTone.success => (
        JobbeesColors.success.withValues(alpha: 0.12),
        JobbeesColors.success,
      ),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: JRadius.heroAll),
      child: Icon(icon, size: size * 0.45, color: fg),
    );
  }
}
