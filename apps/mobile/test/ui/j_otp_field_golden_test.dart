// Golden for the OTP field's focused state — locks the single clean focus ring
// (a soft accent glow), guarding against the doubled/nested-box regression.
// Regenerate with: flutter test --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/theme/app_theme.dart';
import 'package:jobbees_mobile/ui/ui.dart';

import '../support/load_test_fonts.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('OTP field renders a single clean focus ring', (tester) async {
    tester.view.physicalSize = const Size(390, 160);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: JobbeesTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(JSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: JOtpField(controller: controller),
            ),
          ),
        ),
      ),
    );
    // First box auto-focuses; let the focus animation settle.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(JOtpField),
      matchesGoldenFile('goldens/otp_field.png'),
    );
  });
}
