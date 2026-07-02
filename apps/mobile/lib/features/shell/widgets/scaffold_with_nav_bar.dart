// ignore_for_file: public_member_api_docs

/// The authenticated app shell: a persistent Material 3 bottom [NavigationBar]
/// with a raised centre "Post a job" FAB, per docs/brand/UI-PRINCIPLES.md
/// § Bottom navigation (Home / Offers / Post Job / Messages / Profile).
///
/// Wraps a go_router [StatefulNavigationShell] so each tab keeps its own
/// navigation stack — drilling into a tab (and its back button) doesn't lose the
/// nav bar or the other tabs' state. Post is a full-screen create flow pushed on
/// the root navigator, so it's a FAB rather than a branch.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../ui/ui.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      // Round Post action cradled in the nav bar's notch. Full-screen create
      // flow pushed on the root navigator (covers the nav bar).
      floatingActionButton: JPostButton(
        onPressed: () {
          JHaptics.navigation();
          context.push('/post');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: JBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onSelect: _onTap,
        destinations: const [
          JNavDestination(icon: LucideIcons.house, label: 'Home'),
          JNavDestination(icon: LucideIcons.handshake, label: 'Offers'),
          JNavDestination(icon: LucideIcons.messageCircle, label: 'Messages'),
          JNavDestination(icon: LucideIcons.user, label: 'Profile'),
        ],
      ),
    );
  }

  void _onTap(int index) {
    // Subtle selection tick on tab switch — per docs/brand/UI-PRINCIPLES §
    // Haptics ("Navigation tap (chip select, tab switch)"). Skipped when
    // re-tapping the active tab since that's a pop-to-root, not a switch.
    if (index != navigationShell.currentIndex) {
      JHaptics.navigation();
    }
    // Re-tapping the active tab pops it back to the branch root (standard).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
