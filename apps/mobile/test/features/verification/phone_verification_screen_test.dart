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

/// Runs the screen with reduced motion so JEntrance renders its destination
/// state immediately (no pending entrance timers to hang `pumpAndSettle`).
void _reduceMotion(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

/// Types [code] into the redesigned OTP entry (JOtpField), one digit per box.
///
/// The field renders six separate `TextField`s (each `maxLength: 1`), so the
/// old single-field `enterText` no longer works. We drive each box in turn;
/// entering the final digit fires `onCompleted`, which auto-submits the code
/// after a short delay — callers pump past that to let the verify run.
Future<void> _enterOtp(WidgetTester tester, String code) async {
  final boxes = find.byType(TextField);
  for (var i = 0; i < code.length; i++) {
    await tester.enterText(boxes.at(i), code[i]);
    await tester.pump();
  }
}

void main() {
  testWidgets('blocks sending until a valid phone number is entered', (
    tester,
  ) async {
    _reduceMotion(tester);
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
    _reduceMotion(tester);
    final repo = _FakeVerifyRepo();
    final controller = FakeAuthController(initialUser: testUser);
    await _open(tester, repo: repo, controller: controller);

    await tester.enterText(find.byType(TextField), '+61400000000');
    await _tap(tester, 'Send code');
    expect(repo.sendCount, 1);

    // Now on the code step: fill the six OTP boxes. Entering the last digit
    // auto-submits (JOtpField.onCompleted), so we pump past that ~120ms delay
    // and let the verify + reload + pop settle.
    await _enterOtp(tester, '000000');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(repo.verifyCount, 1);
    expect(controller.reloadProfileCount, 1);
    expect(find.text('open-phone'), findsOneWidget); // popped back to the hub
  });

  testWidgets('a verify failure shows the error and stays on the code step', (
    tester,
  ) async {
    _reduceMotion(tester);
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
    // Entering the sixth digit auto-submits; the verify fails on the wrong code.
    await _enterOtp(tester, '111111');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('That code is wrong'), findsOneWidget);
    expect(find.text('open-phone'), findsNothing); // did not pop
  });
}
