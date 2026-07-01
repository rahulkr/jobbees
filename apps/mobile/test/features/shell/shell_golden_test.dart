// Golden of the authenticated shell: the Home tab with the Material 3 bottom
// NavigationBar (Home / Offers / Messages / Profile) and the raised centre
// "Post a job" FAB. Locks the nav-bar + FAB layout. Regenerate with:
//   flutter test --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_support.dart';
import '../../support/load_test_fonts.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('authenticated shell — Home tab, bottom nav + Post FAB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await OnboardingRepository(prefs).markWelcomeSeen();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...signedInOverrides(),
        ],
        child: const JobbeesApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300)); // splash hold
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/shell_home.png'),
    );
  });
}
