// ignore_for_file: public_member_api_docs

/// A [LayoutBuilder]-driven widget that picks a subtree per [WindowSizeClass]
/// (FW-01).
library;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Builds different subtrees for compact / medium / expanded windows.
///
/// [compact] (phone) is the required baseline. [medium] and [expanded] are
/// optional and fall back to the next-smaller builder when omitted, so a
/// screen can opt into wider layouts one breakpoint at a time.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (Breakpoints.classify(constraints.maxWidth)) {
          case WindowSizeClass.expanded:
            return (expanded ?? medium ?? compact)(context);
          case WindowSizeClass.medium:
            return (medium ?? compact)(context);
          case WindowSizeClass.compact:
            return compact(context);
        }
      },
    );
  }
}
