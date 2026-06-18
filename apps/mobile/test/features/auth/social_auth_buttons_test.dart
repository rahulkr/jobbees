import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/widgets/social_auth_buttons.dart';

import '../../support/auth_test_support.dart';

Future<FakeAuthController> _pump(
  WidgetTester tester, {
  Object? socialError,
  void Function(String)? onError,
}) async {
  final controller = FakeAuthController(socialError: socialError);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(
        home: Scaffold(body: SocialAuthButtons(onError: onError)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('renders the Google button', (tester) async {
    await _pump(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('tapping Google calls the controller', (tester) async {
    final controller = await _pump(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(controller.googleCount, 1);
  });

  testWidgets('reports a provider failure via onError', (tester) async {
    String? reported;
    await _pump(
      tester,
      socialError: const AppError('Google sign-in failed. Please try again.'),
      onError: (message) {
        if (message.isNotEmpty) reported = message;
      },
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(reported, 'Google sign-in failed. Please try again.');
  });
}
