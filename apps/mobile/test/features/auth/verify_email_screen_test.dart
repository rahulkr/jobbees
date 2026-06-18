import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_providers.dart';
import 'package:jobbees_mobile/features/auth/screens/verify_email_screen.dart';

import '../../support/auth_test_support.dart';

class _ThrowingRepo extends FakeAuthRepository {
  @override
  Future<void> verifyEmail(String token) async => throw StateError('expired');
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeAuthRepository repo,
  String? token,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: VerifyEmailScreen(token: token)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('verifies the token on load and shows success', (tester) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo: repo, token: 'verify-token');

    expect(repo.lastVerifyToken, 'verify-token');
    expect(find.text('Email verified'), findsOneWidget);
  });

  testWidgets('shows the expired state when there is no token', (tester) async {
    final repo = FakeAuthRepository();
    await _pump(tester, repo: repo, token: null);

    expect(repo.lastVerifyToken, isNull);
    expect(find.text('This link has expired'), findsOneWidget);
  });

  testWidgets('shows the expired state when verification fails', (
    tester,
  ) async {
    await _pump(tester, repo: _ThrowingRepo(), token: 'bad-token');

    expect(find.text('This link has expired'), findsOneWidget);
  });
}
