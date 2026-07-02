import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/profile/models/public_tasker_profile.dart';
import 'package:jobbees_mobile/features/profile/providers/profile_providers.dart';
import 'package:jobbees_mobile/features/profile/screens/public_tasker_profile_screen.dart';

void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('renders the public profile: name, badges, rate, skills', (
    tester,
  ) async {
    _reduceMotion(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicTaskerProfileProvider('t1').overrideWith(
            (ref) async => const PublicTaskerProfile(
              id: 't1',
              firstName: 'Sam',
              bio: 'Reliable handyman',
              hourlyRateCents: 8500,
              businessName: 'Sam Pty Ltd',
              skills: ['plumbing', 'tiling'],
              badges: TaskerBadges(email: true, phone: true, payments: true),
            ),
          ),
        ],
        child: const MaterialApp(
          home: PublicTaskerProfileScreen(taskerId: 't1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Sam Pty Ltd'), findsOneWidget);
    expect(find.text('\$85/hr'), findsOneWidget);
    expect(find.text('plumbing'), findsOneWidget);
    expect(find.text('Email verified'), findsOneWidget);
    expect(find.text('Payments ready'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('hides badges that are not earned', (tester) async {
    _reduceMotion(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicTaskerProfileProvider('t2').overrideWith(
            (ref) async => const PublicTaskerProfile(
              id: 't2',
              firstName: 'Alex',
              skills: [],
              badges: TaskerBadges(email: true),
            ),
          ),
        ],
        child: const MaterialApp(
          home: PublicTaskerProfileScreen(taskerId: 't2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email verified'), findsOneWidget);
    expect(find.text('Phone verified'), findsNothing);
    expect(find.text('Payments ready'), findsNothing);
  });
}
