// Full-router redirect tests for the cold-launch sequence. These exercise the
// real GoRouter (splash → welcome → auth gate), which the per-screen tests
// don't — the gap that let a fresh-signed-out redirect loop reach main.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_support.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required bool welcomeSeen,
  required bool signedIn,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (welcomeSeen) await OnboardingRepository(prefs).markWelcomeSeen();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(
          () => FakeAuthController(initialUser: signedIn ? testUser : null),
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
    expect(find.text('Post a job'), findsOneWidget); // home shell
  });
}
