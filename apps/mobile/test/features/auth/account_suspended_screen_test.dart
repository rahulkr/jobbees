import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/screens/account_suspended_screen.dart';

import '../../support/auth_test_support.dart';

void main() {
  testWidgets('shows the suspended notice and logs out on the CTA', (
    tester,
  ) async {
    final controller = FakeAuthController(initialUser: suspendedUser);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AccountSuspendedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account suspended'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(controller.logoutCount, 1);
  });
}
