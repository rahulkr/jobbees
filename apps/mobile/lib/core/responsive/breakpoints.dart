// ignore_for_file: public_member_api_docs

/// Responsive layout breakpoints for the JOBBees shell (FW-01).
///
/// One Flutter codebase renders phone, tablet, and desktop-web. Screens choose
/// a layout from [WindowSizeClass] instead of hard-coding phone-shaped widths,
/// so the Sprint 2+ web-parity rows can land without rewriting layouts.
library;

import 'package:flutter/widgets.dart';

/// Coarse size buckets, aligned with Material 3 window size classes.
enum WindowSizeClass { compact, medium, expanded }

class Breakpoints {
  Breakpoints._();

  /// At/above this logical width the surface is treated as a tablet.
  static const double medium = 600;

  /// At/above this logical width the surface is treated as desktop-web.
  static const double expanded = 1024;

  /// Maps a width (logical pixels) to its [WindowSizeClass].
  static WindowSizeClass classify(double width) {
    if (width >= expanded) return WindowSizeClass.expanded;
    if (width >= medium) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// Resolves the size class from the nearest [MediaQuery].
  static WindowSizeClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);
}
