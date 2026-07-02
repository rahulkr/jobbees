// Smoke tests for the Flutter Web foundation shell (FW-01..03).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/core/responsive/breakpoints.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:jobbees_mobile/ui/ui.dart';
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

/// Runs with reduced motion so the redesigned splash/home entrance and
/// "breathing" animations collapse to their destination state — otherwise the
/// infinite animations leave `pumpAndSettle` spinning and the splash never hands
/// off within the pumped window.
void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('lands on the Home tab inside the bottom-nav shell', (
    tester,
  ) async {
    _reduceMotion(tester);
    await _pumpHome(tester);

    // The Home tab is a designed greeting header + empty state, not an app bar.
    expect(find.text('What needs doing?'), findsOneWidget); // Home header
    expect(find.text('Your feed is warming up'), findsOneWidget); // empty state
    // The composed bottom nav + cradled centre Post button.
    expect(find.byType(JBottomNav), findsOneWidget);
    expect(find.byType(JPostButton), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('the Post FAB opens the full-screen post-a-job flow', (
    tester,
  ) async {
    _reduceMotion(tester);
    await _pumpHome(tester);

    await tester.tap(find.byType(JPostButton));
    await tester.pumpAndSettle();

    expect(find.text('/post'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('the bottom nav switches to the Profile tab', (tester) async {
    _reduceMotion(tester);
    await _pumpHome(tester);
    expect(find.text('What needs doing?'), findsOneWidget); // on the Home tab

    // Target the nav destination specifically — the Profile branch's own
    // "Profile" app-bar title also matches once that tab is built.
    await tester.tap(
      find.descendant(
        of: find.byType(JBottomNav),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    // Profile branch is shown; the Home tab is now offstage.
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('What needs doing?'), findsNothing);
  });

  testWidgets('compact layout drives a phone-shaped home body', (tester) async {
    _reduceMotion(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpHome(tester);

    // Compact width renders the phone-shaped Home body (its greeting header).
    expect(find.text('What needs doing?'), findsOneWidget);
  });

  group('Breakpoints', () {
    test('classifies widths into window size classes', () {
      expect(Breakpoints.classify(390), WindowSizeClass.compact);
      expect(Breakpoints.classify(800), WindowSizeClass.medium);
      expect(Breakpoints.classify(1280), WindowSizeClass.expanded);
    });
  });
}
