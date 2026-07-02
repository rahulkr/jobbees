import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/profile/screens/my_profile_screen.dart';

import '../../support/auth_test_support.dart';

const _taskerUser = UserProfile(
  id: 'user_tasker',
  email: 'jordan@example.com',
  firstName: 'Jordan',
  lastName: 'Lee',
  role: UserRole.tasker,
  emailVerified: true,
  phoneVerified: true,
);

Future<FakeAuthController> _pump(
  WidgetTester tester, {
  required UserProfile user,
}) async {
  final controller = FakeAuthController(initialUser: user);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: const MaterialApp(home: MyProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

void main() {
  testWidgets('shows the account name and email', (tester) async {
    _reduceMotion(tester);
    await _pump(tester, user: testUser);

    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('jordan@example.com'), findsOneWidget);
  });

  testWidgets('a client sees the become-a-tasker upgrade, not tasker entries', (
    tester,
  ) async {
    _reduceMotion(tester);
    await _pump(tester, user: testUser); // testUser is a client

    expect(find.text('Become a tasker'), findsOneWidget);
    expect(find.text('My tasker profile'), findsNothing);
    expect(find.text('Verification'), findsNothing);
  });

  testWidgets('a tasker sees verification + profile + switch-to-client', (
    tester,
  ) async {
    _reduceMotion(tester);
    await _pump(tester, user: _taskerUser);

    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('My tasker profile'), findsOneWidget);
    expect(find.text('Switch to client'), findsOneWidget);
    expect(find.text('Become a tasker'), findsNothing);
  });

  testWidgets('confirming switch-to-client calls the controller', (
    tester,
  ) async {
    _reduceMotion(tester);
    final controller = await _pump(tester, user: _taskerUser);

    await tester.tap(find.text('Switch to client')); // the tile
    await tester.pumpAndSettle();

    // Confirm bottom sheet is open; nothing has happened yet.
    expect(find.text('Switch to client?'), findsOneWidget);
    expect(controller.switchToClientCount, 0);

    // Tap the sheet's confirm button (a JButton labelled with the restated
    // action, distinct from the 'Switch to client' tile behind the sheet).
    await tester.tap(find.text('Yes, switch to client'));
    await tester.pumpAndSettle();

    expect(controller.switchToClientCount, 1);
  });

  testWidgets('cancelling switch-to-client does nothing', (tester) async {
    _reduceMotion(tester);
    final controller = await _pump(tester, user: _taskerUser);

    await tester.tap(find.text('Switch to client'));
    await tester.pumpAndSettle();
    // The sheet's dismiss action is a JButton labelled 'Keep both'.
    await tester.tap(find.text('Keep both'));
    await tester.pumpAndSettle();

    expect(controller.switchToClientCount, 0);
  });

  testWidgets('tapping log out calls the controller', (tester) async {
    _reduceMotion(tester);
    final controller = await _pump(tester, user: testUser);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(controller.logoutCount, 1);
  });
}
