import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/verification/data/verification_repository.dart';
import 'package:jobbees_mobile/features/verification/providers/verification_providers.dart';
import 'package:jobbees_mobile/features/verification/screens/phone_verification_screen.dart';

import '../../support/auth_test_support.dart';

class _FakeVerifyRepo extends VerificationRepository {
  _FakeVerifyRepo({this.verifyError})
    : super(Dio(), newIdempotencyKey: () => 'k');

  final Object? verifyError;
  int sendCount = 0;
  int verifyCount = 0;

  @override
  Future<void> sendPhoneOtp(String phone) async => sendCount++;

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String code,
  }) async {
    verifyCount++;
    if (verifyError != null) throw verifyError!;
  }
}

GoRouter _router() => GoRouter(
  initialLocation: '/verify',
  routes: [
    GoRoute(
      path: '/verify',
      builder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.push('/verify/phone'),
            child: const Text('open-phone'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/verify/phone',
      builder: (context, state) => const PhoneVerificationScreen(),
    ),
  ],
);

Future<void> _open(
  WidgetTester tester, {
  required _FakeVerifyRepo repo,
  required FakeAuthController controller,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.tap(find.text('open-phone'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('blocks sending until a valid phone number is entered', (
    tester,
  ) async {
    final repo = _FakeVerifyRepo();
    await _open(tester, repo: repo, controller: FakeAuthController());

    await _tap(tester, 'Send code');

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(repo.sendCount, 0);

    final phone = tester.widget<TextField>(find.byType(TextField));
    expect(phone.focusNode?.hasFocus, isTrue);
  });

  testWidgets('sends the code, verifies, reloads the profile, and returns', (
    tester,
  ) async {
    final repo = _FakeVerifyRepo();
    final controller = FakeAuthController(initialUser: testUser);
    await _open(tester, repo: repo, controller: controller);

    await tester.enterText(find.byType(TextField), '+61400000000');
    await _tap(tester, 'Send code');
    expect(repo.sendCount, 1);

    // Now on the code step.
    await tester.enterText(find.byType(TextField), '000000');
    await _tap(tester, 'Verify');

    expect(repo.verifyCount, 1);
    expect(controller.reloadProfileCount, 1);
    expect(find.text('open-phone'), findsOneWidget); // popped back to the hub
  });

  testWidgets('a verify failure shows the error and stays on the code step', (
    tester,
  ) async {
    final repo = _FakeVerifyRepo(
      verifyError: const AppError('That code is wrong'),
    );
    await _open(
      tester,
      repo: repo,
      controller: FakeAuthController(initialUser: testUser),
    );

    await tester.enterText(find.byType(TextField), '+61400000000');
    await _tap(tester, 'Send code');
    await tester.enterText(find.byType(TextField), '111111');
    await _tap(tester, 'Verify');

    expect(find.text('That code is wrong'), findsOneWidget);
    expect(find.text('open-phone'), findsNothing); // did not pop
  });
}
