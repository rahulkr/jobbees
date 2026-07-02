// ignore_for_file: public_member_api_docs

/// JAppBar — the standard top bar for drill-down screens.
///
/// A thin composed wrapper over Material's [AppBar] (already themed by the app:
/// surface background, Inter 18/w600, flat) that swaps the default back arrow for
/// a [JPressable] Lucide chevron (press feedback + nav haptic) and centres the
/// title. Use this instead of a bare `AppBar` so every screen's chrome is one
/// component (Design Quality Charter § "no default Material widgets").
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../platform/j_pressable.dart';

class JAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JAppBar({this.title, this.actions, this.showBack = true, super.key});

  final String? title;
  final List<Widget>? actions;

  /// Show the back affordance when the route can pop. Set false for a root
  /// destination that shouldn't offer "back".
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: title == null ? null : Text(title!),
      leading: (showBack && canPop)
          ? JPressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Center(child: Icon(LucideIcons.chevronLeft)),
            )
          : null,
      actions: actions,
    );
  }
}
