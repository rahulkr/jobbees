import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/onboarding/providers/onboarding_providers.dart';
import 'package:jobbees_mobile/features/onboarding/screens/welcome_carousel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpCarousel(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: WelcomeCarouselScreen()),
    ),
  );
  return container;
}

void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('renders the first slide with Skip and Next', (tester) async {
    _reduceMotion(tester);
    await _pumpCarousel(tester);

    expect(find.text('Post a job in minutes'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('Next advances through slides to Get started', (tester) async {
    _reduceMotion(tester);
    await _pumpCarousel(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Earn on your terms'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Safe and local'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('Skip marks the carousel as seen', (tester) async {
    _reduceMotion(tester);
    final container = await _pumpCarousel(tester);
    expect(container.read(welcomeSeenProvider), isFalse);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(container.read(welcomeSeenProvider), isTrue);
  });

  testWidgets('Get started marks the carousel as seen', (tester) async {
    _reduceMotion(tester);
    final container = await _pumpCarousel(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(container.read(welcomeSeenProvider), isTrue);
  });
}
