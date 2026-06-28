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

void main() {
  testWidgets('shows the account name and email', (tester) async {
    await _pump(tester, user: testUser);

    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('jordan@example.com'), findsOneWidget);
  });

  testWidgets('a client sees the become-a-tasker upgrade, not tasker entries', (
    tester,
  ) async {
    await _pump(tester, user: testUser); // testUser is a client

    expect(find.text('Become a tasker'), findsOneWidget);
    expect(find.text('My tasker profile'), findsNothing);
    expect(find.text('Verification'), findsNothing);
  });

  testWidgets('a tasker sees verification + profile entries, no upgrade', (
    tester,
  ) async {
    await _pump(tester, user: _taskerUser);

    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('My tasker profile'), findsOneWidget);
    expect(find.text('Become a tasker'), findsNothing);
  });

  testWidgets('tapping log out calls the controller', (tester) async {
    final controller = await _pump(tester, user: testUser);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(controller.logoutCount, 1);
  });
}
