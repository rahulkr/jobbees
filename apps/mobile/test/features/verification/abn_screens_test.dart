import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/verification/models/abn_status.dart';
import 'package:jobbees_mobile/features/verification/providers/verification_providers.dart';
import 'package:jobbees_mobile/features/verification/screens/abn_entry_screen.dart';
import 'package:jobbees_mobile/features/verification/screens/verification_status_screen.dart';

class _FakeController extends AbnStatusController {
  _FakeController({this.initial = const AbnStatus(), this.submitError});

  final AbnStatus initial;
  final Object? submitError;
  int submitCount = 0;

  @override
  Future<AbnStatus> build() async => initial;

  @override
  Future<void> submit(String abn) async {
    submitCount++;
    if (submitError != null) throw submitError!;
    state = AsyncData(AbnStatus(abn: abn, verifiedAt: DateTime(2026)));
  }
}

Future<_FakeController> _pump(
  WidgetTester tester,
  Widget screen, {
  AbnStatus initial = const AbnStatus(),
  Object? submitError,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakeController(
    initial: initial,
    submitError: submitError,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [abnStatusProvider.overrideWith(() => controller)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('AbnEntryScreen', () {
    testWidgets('blocks submit and shows an error on a bad ABN', (
      tester,
    ) async {
      final controller = await _pump(tester, const AbnEntryScreen());

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Verify ABN'));
      await tester.pumpAndSettle();

      expect(controller.submitCount, 0);
      expect(find.text('Enter your 11-digit ABN'), findsOneWidget);
    });

    testWidgets('moves focus to the ABN field on a failed submit', (
      tester,
    ) async {
      await _pump(tester, const AbnEntryScreen());

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Verify ABN'));
      await tester.pumpAndSettle();

      final abn = tester.widget<TextField>(find.byType(TextField));
      expect(abn.focusNode?.hasFocus, isTrue);
    });

    testWidgets('submits a well-formed ABN and surfaces a server error', (
      tester,
    ) async {
      final controller = await _pump(
        tester,
        const AbnEntryScreen(),
        submitError: const AppError('That ABN is not valid.'),
      );

      await tester.enterText(find.byType(TextField), '51824753556');
      await tester.tap(find.text('Verify ABN'));
      await tester.pumpAndSettle();

      expect(controller.submitCount, 1);
      expect(find.text('That ABN is not valid.'), findsOneWidget);
    });
  });

  group('VerificationStatusScreen', () {
    testWidgets('shows the empty state with an Add ABN action', (tester) async {
      await _pump(tester, const VerificationStatusScreen());

      expect(find.text('Not added'), findsOneWidget);
      expect(find.text('Add ABN'), findsOneWidget);
    });

    testWidgets('shows the verified state with business name', (tester) async {
      await _pump(
        tester,
        const VerificationStatusScreen(),
        initial: AbnStatus(
          abn: '51824753556',
          businessName: 'Test Business Pty Ltd',
          verifiedAt: DateTime(2026),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Test Business Pty Ltd'), findsOneWidget);
      expect(find.text('Update ABN'), findsOneWidget);
    });
  });
}
