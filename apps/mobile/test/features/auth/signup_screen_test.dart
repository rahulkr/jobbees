import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/screens/signup_screen.dart';

import '../../support/auth_test_support.dart';

Future<FakeAuthController> _pumpSignup(
  WidgetTester tester, {
  Object? signUpError,
  bool revealEmailForm = true,
}) async {
  // Tall surface so the scrollable form's submit button is on-screen for taps.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = FakeAuthController(signUpError: signUpError);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: const MaterialApp(home: SignupScreen()),
    ),
  );
  await tester.pumpAndSettle();
  if (revealEmailForm) {
    // The email form sits behind a "Sign up with email" action (progressive
    // disclosure); reveal it so the form-level tests can reach the fields.
    await tester.tap(find.text('Sign up with email'));
    await tester.pumpAndSettle();
  }
  return controller;
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'Jordan');
  await tester.enterText(find.byType(TextField).at(1), 'Lee');
  await tester.enterText(find.byType(TextField).at(2), 'jordan@example.com');
  await tester.enterText(find.byType(TextField).at(3), 'a-strong-passphrase');
}

void main() {
  testWidgets('keeps the email form collapsed until requested', (tester) async {
    await _pumpSignup(tester, revealEmailForm: false);

    // Socials lead; the email form and its CTA are hidden until opted into.
    expect(find.text('Sign up with email'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Create account'), findsNothing);

    await tester.tap(find.text('Sign up with email'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('blocks submit and shows validation when fields are empty', (
    tester,
  ) async {
    final controller = await _pumpSignup(tester);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(controller.signUpCount, 0);
    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('flags a password shorter than 10 characters', (tester) async {
    final controller = await _pumpSignup(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Jordan');
    await tester.enterText(find.byType(TextField).at(1), 'Lee');
    await tester.enterText(find.byType(TextField).at(2), 'jordan@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(controller.signUpCount, 0);
    expect(find.text('Use at least 10 characters'), findsOneWidget);
  });

  testWidgets('submits a valid form to the controller', (tester) async {
    final controller = await _pumpSignup(tester);

    await _fillValidForm(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(controller.signUpCount, 1);
  });

  testWidgets('renders a server error in a snackbar', (tester) async {
    await _pumpSignup(
      tester,
      signUpError: const AppError('That account already exists.'),
    );

    await _fillValidForm(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('That account already exists.'), findsOneWidget);
  });

  testWidgets('offers example hints on the name fields', (tester) async {
    await _pumpSignup(tester);

    // Hints render as placeholder text while the fields are empty.
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Lee'), findsOneWidget);
  });

  testWidgets('moves focus to the first invalid field on a failed submit', (
    tester,
  ) async {
    await _pumpSignup(tester);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final firstName = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(firstName.focusNode?.hasFocus, isTrue);
  });
}
