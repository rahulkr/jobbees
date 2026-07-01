// Smoke tests for the Flutter Web foundation shell (FW-01..03).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/core/responsive/breakpoints.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/auth_test_support.dart';

/// Boots the app as a returning, signed-in user (onboarding seen + a live
/// session) and drives past the splash hold so we land on the home shell — the
/// surface these foundation tests assert on. First-run onboarding and the auth
/// gate are covered in test/features/.
Future<void> _pumpHome(WidgetTester tester) async {
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

  // Fire the splash hold timer, then let routing settle onto home.
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lands on the Home tab inside the bottom-nav shell', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('JOBBees'), findsOneWidget); // Home tab app bar
    expect(find.text('Welcome to JOBBees'), findsOneWidget);
    // The Material 3 bottom nav + centre Post FAB.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('the Post FAB opens the full-screen post-a-job flow', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('/post'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('the bottom nav switches to the Profile tab', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Welcome to JOBBees'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Profile branch is shown; the Home tab is now offstage.
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Welcome to JOBBees'), findsNothing);
  });

  testWidgets('compact layout drives a phone-shaped home body', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpHome(tester);

    expect(find.text('JOBBees'), findsOneWidget);
  });

  group('Breakpoints', () {
    test('classifies widths into window size classes', () {
      expect(Breakpoints.classify(390), WindowSizeClass.compact);
      expect(Breakpoints.classify(800), WindowSizeClass.medium);
      expect(Breakpoints.classify(1280), WindowSizeClass.expanded);
    });
  });
}
