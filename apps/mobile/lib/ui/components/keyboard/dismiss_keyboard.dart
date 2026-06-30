/// DismissKeyboard — tap outside a field to close the soft keyboard.
///
/// Flutter does not dismiss the keyboard when you tap empty space; wrap a
/// screen body in this so any tap on a non-interactive area unfocuses the
/// active field. Pair it with `keyboardDismissBehavior:
/// ScrollViewKeyboardDismissBehavior.onDrag` on the screen's scroll view so a
/// swipe over the form drags the keyboard away too.
///
/// [HitTestBehavior.translucent] lets the gesture register on the padding /
/// background while still letting children win the gesture arena for their own
/// taps — buttons, links and fields keep working, only empty space dismisses.
///
/// Usage:
///   Scaffold(body: DismissKeyboard(child: SafeArea(child: ...)))

library;

import 'package:flutter/material.dart';

class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
