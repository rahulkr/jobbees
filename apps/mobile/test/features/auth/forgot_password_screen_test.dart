import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_providers.dart';
import 'package:jobbees_mobile/features/auth/screens/forgot_password_screen.dart';

import '../../support/auth_test_support.dart';

Future<FakeAuthRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ForgotPasswordScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('validates the email before sending', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(repo.forgotCount, 0);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('sends the request and shows the confirmation', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'jordan@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(repo.forgotCount, 1);
    expect(find.text('Check your email'), findsOneWidget);
  });
}
