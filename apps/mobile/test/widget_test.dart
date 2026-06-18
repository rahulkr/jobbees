// Smoke tests for the Flutter Web foundation shell (FW-01..03).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/core/responsive/breakpoints.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the app as a returning user (onboarding already seen) and drives past
/// the splash hold so we land on the home shell — the surface these foundation
/// tests assert on. First-run onboarding (splash → welcome) is covered in
/// test/features/onboarding/.
Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await OnboardingRepository(prefs).markWelcomeSeen();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const JobbeesApp(),
    ),
  );

  // Fire the splash hold timer, then let routing settle onto home.
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home screen renders and routes to a placeholder', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('JOBBees'), findsOneWidget);
    expect(find.text('Post a job'), findsOneWidget);

    await tester.tap(find.text('Post a job'));
    await tester.pumpAndSettle();

    // go_router navigated to the placeholder route.
    expect(find.text('/post'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
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
