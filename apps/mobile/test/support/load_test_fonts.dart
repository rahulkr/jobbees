import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the Lucide icon font so golden tests render real icons instead of tofu
/// boxes. (Inter loads automatically from the bundled `assets/google_fonts/` via
/// google_fonts' asset resolution, so it doesn't need loading here.)
Future<void> loadTestFonts() async {
  final loader = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await loader.load();
}
