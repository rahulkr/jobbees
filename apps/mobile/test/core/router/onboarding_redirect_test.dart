// Full-router redirect tests for the cold-launch sequence. These exercise the
// real GoRouter (splash → welcome → auth gate), which the per-screen tests
// don't — the gap that let a fresh-signed-out redirect loop reach main.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/providers/biometric_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_support.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required bool welcomeSeen,
  bool signedIn = false,
  bool biometricEnabled = false,
  UserProfile? user,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (welcomeSeen) await OnboardingRepository(prefs).markWelcomeSeen();
  if (biometricEnabled) await prefs.setBool('auth.biometric_enabled.v1', true);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // The /unlock auto-prompt must not hit the real plugin; keep it
        // unauthenticated so a locked session stays on the unlock screen.
        biometricAuthServiceProvider.overrideWithValue(
          FakeBiometricAuthService(authenticateResult: false),
        ),
        authControllerProvider.overrideWith(
          () => FakeAuthController(
            initialUser: user ?? (signedIn ? testUser : null),
          ),
        ),
      ],
      child: const JobbeesApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1300)); // splash hold
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fresh signed-out launch lands on the welcome carousel', (
    tester,
  ) async {
    await _pumpApp(tester, welcomeSeen: false, signedIn: false);

    expect(find.text('Page Not Found'), findsNothing);
    expect(find.text('Skip'), findsOneWidget); // welcome carousel
  });

  testWidgets('returning signed-out user lands on login', (tester) async {
    await _pumpApp(tester, welcomeSeen: true, signedIn: false);

    expect(find.text('Page Not Found'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget); // login header
  });

  testWidgets('signed-in user lands on home', (tester) async {
    await _pumpApp(tester, welcomeSeen: true, signedIn: true);

    expect(find.text('Page Not Found'), findsNothing);
    expect(
      find.text('Welcome to JOBBees'),
      findsOneWidget,
    ); // home tab in shell
  });

  testWidgets('a suspended session lands on the account-suspended screen', (
    tester,
  ) async {
    await _pumpApp(tester, welcomeSeen: true, user: suspendedUser);

    expect(find.text('Page Not Found'), findsNothing);
    expect(find.text('Account suspended'), findsOneWidget);
  });

  testWidgets('a signed-in user with biometrics enabled lands on unlock', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      welcomeSeen: true,
      signedIn: true,
      biometricEnabled: true,
    );

    expect(find.text('Page Not Found'), findsNothing);
    expect(find.text('Use password instead'), findsOneWidget); // unlock screen
  });
}
