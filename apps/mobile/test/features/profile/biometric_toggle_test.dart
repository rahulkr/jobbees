import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/providers/biometric_providers.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:jobbees_mobile/features/profile/screens/my_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_support.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required FakeBiometricAuthService biometrics,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricAuthServiceProvider.overrideWithValue(biometrics),
        authControllerProvider.overrideWith(
          () => FakeAuthController(initialUser: testUser),
        ),
      ],
      child: const MaterialApp(home: MyProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(MyProfileScreen)),
    listen: false,
  );
}

void main() {
  testWidgets('shows the biometric toggle when the device supports it', (
    tester,
  ) async {
    await _pump(tester, biometrics: FakeBiometricAuthService(available: true));
    expect(find.text('Biometric unlock'), findsOneWidget);
  });

  testWidgets('hides the toggle when biometrics are unavailable', (
    tester,
  ) async {
    await _pump(tester, biometrics: FakeBiometricAuthService(available: false));
    expect(find.text('Biometric unlock'), findsNothing);
  });

  testWidgets('enabling the toggle verifies, then persists the flag', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      biometrics: FakeBiometricAuthService(
        available: true,
        authenticateResult: true,
      ),
    );
    expect(container.read(biometricEnabledProvider), isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(container.read(biometricEnabledProvider), isTrue);
  });
}
