import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/screens/login_screen.dart';

import '../../support/auth_test_support.dart';

Future<FakeAuthController> _pumpLogin(
  WidgetTester tester, {
  Object? loginError,
}) async {
  // Tall surface so the scrollable form's submit button is on-screen for taps.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = FakeAuthController(loginError: loginError);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('validates email and password before submitting', (tester) async {
    final controller = await _pumpLogin(tester);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.loginCount, 0);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('submits valid credentials to the controller', (tester) async {
    final controller = await _pumpLogin(tester);

    await tester.enterText(find.byType(TextField).at(0), 'jordan@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'a-strong-passphrase');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.loginCount, 1);
  });

  testWidgets('shows a server error in a snackbar (no Retry on 4xx)', (
    tester,
  ) async {
    await _pumpLogin(
      tester,
      loginError: const AppError('Incorrect email or password.'),
    );

    await tester.enterText(find.byType(TextField).at(0), 'jordan@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-passphrase');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    // A wrong-credentials error is not retryable, so no Retry action.
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('offers Retry on a transient error and re-runs the submit', (
    tester,
  ) async {
    final controller = await _pumpLogin(
      tester,
      loginError: const AppError(
        "Can't reach JOBBees right now.",
        retryable: true,
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'jordan@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'a-strong-passphrase');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text("Can't reach JOBBees right now."), findsOneWidget);
    expect(controller.loginCount, 1);

    // Tapping Retry re-runs the login without re-entering anything.
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(controller.loginCount, 2);
  });
}
