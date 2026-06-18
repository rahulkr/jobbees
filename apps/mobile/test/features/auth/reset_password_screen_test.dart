import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_providers.dart';
import 'package:jobbees_mobile/features/auth/screens/reset_password_screen.dart';

import '../../support/auth_test_support.dart';

Future<FakeAuthRepository> _pump(WidgetTester tester, {String? token}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: ResetPasswordScreen(token: token)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows the invalid-link state without a token', (tester) async {
    await _pump(tester);

    expect(find.text('This link has expired'), findsOneWidget);
    expect(find.text('Update password'), findsNothing);
  });

  testWidgets('flags mismatched passwords', (tester) async {
    final repo = await _pump(tester, token: 'reset-token');

    await tester.enterText(find.byType(TextField).at(0), 'a-strong-passphrase');
    await tester.enterText(
      find.byType(TextField).at(1),
      'different-passphrase',
    );
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(repo.lastResetToken, isNull);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('submits the new password with the token', (tester) async {
    final repo = await _pump(tester, token: 'reset-token');

    await tester.enterText(find.byType(TextField).at(0), 'a-strong-passphrase');
    await tester.enterText(find.byType(TextField).at(1), 'a-strong-passphrase');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(repo.lastResetToken, 'reset-token');
    expect(find.text('Password updated'), findsOneWidget);
  });
}
