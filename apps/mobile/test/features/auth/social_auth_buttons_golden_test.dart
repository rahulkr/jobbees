// Golden coverage for the social sign-in button pair — renders the real Google
// (JButton.secondary) and custom Apple (JButton.apple) buttons with their logo
// assets and the app theme, so the matched-pair balance (height/radius/font,
// logo size + gap) can't silently drift. Regenerate with:
//   flutter test --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/theme/app_theme.dart';
import 'package:jobbees_mobile/ui/ui.dart';

import '../../support/load_test_fonts.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('social sign-in buttons render as a matched pair', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 220);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: JobbeesTheme.light(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(JSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  JButton.secondary(
                    label: 'Continue with Google',
                    leading: Image.asset(
                      'assets/social/google.png',
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {},
                    expanded: true,
                    size: JButtonSize.md,
                  ),
                  const SizedBox(height: JSpacing.md),
                  JButton.apple(
                    label: 'Continue with Apple',
                    leading: Image.asset(
                      'assets/social/apple_logo.png',
                      height: 20,
                    ),
                    onPressed: () {},
                    expanded: true,
                    size: JButtonSize.md,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Let the bundled Inter font + logo bytes load before capturing.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/social_auth_buttons.png'),
    );
  });
}
