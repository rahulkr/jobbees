import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/verification/screens/become_tasker_screen.dart';

import '../../support/auth_test_support.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/become-tasker',
  routes: [
    GoRoute(
      path: '/become-tasker',
      builder: (context, state) => const BecomeTaskerScreen(),
    ),
    GoRoute(
      path: '/verify',
      builder: (context, state) => const Text('verify-stub'),
    ),
  ],
);

Future<void> _pump(WidgetTester tester, FakeAuthController controller) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('explains the role switch without upgrade/permanent language', (
    tester,
  ) async {
    await _pump(tester, FakeAuthController(initialUser: testUser));

    expect(find.text('Find work and get paid'), findsOneWidget);
    expect(find.text('Verify your ABN'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Get started switches the role then goes to verification', (
    tester,
  ) async {
    final controller = FakeAuthController(initialUser: testUser);
    await _pump(tester, controller);

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(controller.becomeTaskerCount, 1);
    expect(find.text('verify-stub'), findsOneWidget);
  });

  testWidgets('a failure shows the error banner and stays on the screen', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeAuthController(
        initialUser: testUser,
        becomeTaskerError: const AppError('Could not switch right now'),
      ),
    );

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Could not switch right now'), findsOneWidget);
    expect(find.text('verify-stub'), findsNothing);
  });
}
