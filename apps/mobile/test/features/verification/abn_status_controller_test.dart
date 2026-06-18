import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/verification/data/verification_repository.dart';
import 'package:jobbees_mobile/features/verification/models/abn_status.dart';
import 'package:jobbees_mobile/features/verification/providers/verification_providers.dart';

class _FakeRepo implements VerificationRepository {
  _FakeRepo({this.initial = const AbnStatus(), this.submitError});

  final AbnStatus initial;
  final Object? submitError;
  String? submitted;

  @override
  String Function() get newIdempotencyKey =>
      () => 'k';

  @override
  Future<AbnStatus> fetchAbnStatus() async => initial;

  @override
  Future<AbnStatus> submitAbn(String abn) async {
    submitted = abn;
    if (submitError != null) throw submitError!;
    return AbnStatus(
      abn: abn,
      businessName: 'Acme',
      verifiedAt: DateTime(2026),
    );
  }
}

ProviderContainer _container(_FakeRepo repo) {
  final container = ProviderContainer(
    overrides: [verificationRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('build loads the current ABN status', () async {
    final container = _container(_FakeRepo(initial: const AbnStatus(abn: '5')));

    final status = await container.read(abnStatusProvider.future);

    expect(status.abn, '5');
  });

  test('submit posts the ABN and updates state to verified', () async {
    final repo = _FakeRepo();
    final container = _container(repo);
    await container.read(abnStatusProvider.future);

    await container.read(abnStatusProvider.notifier).submit('51824753556');

    expect(repo.submitted, '51824753556');
    expect(container.read(abnStatusProvider).valueOrNull?.isVerified, isTrue);
  });

  test('submit rethrows failures as AppError', () async {
    final repo = _FakeRepo(
      submitError: const AppError('That ABN is not valid.'),
    );
    final container = _container(repo);
    await container.read(abnStatusProvider.future);

    await expectLater(
      container.read(abnStatusProvider.notifier).submit('111'),
      throwsA(isA<AppError>()),
    );
  });
}
