import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/providers/biometric_providers.dart';
import 'package:jobbees_mobile/features/auth/screens/unlock_screen.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_support.dart';

void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required bool biometricPasses,
  FakeAuthController? controller,
}) async {
  // Start armed: the enabled flag is on, so appLockProvider seeds locked.
  SharedPreferences.setMockInitialValues({'auth.biometric_enabled.v1': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricAuthServiceProvider.overrideWithValue(
          FakeBiometricAuthService(authenticateResult: biometricPasses),
        ),
        if (controller != null)
          authControllerProvider.overrideWith(() => controller),
      ],
      child: const MaterialApp(home: UnlockScreen()),
    ),
  );
  // Fire the post-frame auto-prompt and let the fake authenticate resolve.
  // NOT pumpAndSettle: a successful unlock keeps the button spinner up (the
  // router would navigate away in the real app), which never settles here.
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(UnlockScreen)),
    listen: false,
  );
}

void main() {
  testWidgets('a successful biometric prompt clears the app lock', (
    tester,
  ) async {
    _reduceMotion(tester);
    final container = await _pump(tester, biometricPasses: true);
    expect(container.read(appLockProvider), isFalse);
  });

  testWidgets('a failed prompt keeps the lock and offers the fallback', (
    tester,
  ) async {
    _reduceMotion(tester);
    final container = await _pump(tester, biometricPasses: false);
    expect(container.read(appLockProvider), isTrue);
    expect(find.text('Use password instead'), findsOneWidget);
  });

  testWidgets('the password fallback logs out and clears the lock', (
    tester,
  ) async {
    _reduceMotion(tester);
    final controller = FakeAuthController(initialUser: testUser);
    final container = await _pump(
      tester,
      biometricPasses: false,
      controller: controller,
    );

    await tester.tap(find.text('Use password instead'));
    await tester.pumpAndSettle();

    expect(controller.logoutCount, 1);
    expect(container.read(appLockProvider), isFalse);
  });
}
