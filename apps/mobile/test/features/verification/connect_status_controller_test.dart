import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/network/error_mapper.dart';
import 'package:jobbees_mobile/features/verification/data/connect_repository.dart';
import 'package:jobbees_mobile/features/verification/models/connect_status.dart';
import 'package:jobbees_mobile/features/verification/providers/connect_providers.dart';

const _notStarted = ConnectStatus(
  state: ConnectState.notStarted,
  payoutsEnabled: false,
  detailsSubmitted: false,
);

const _complete = ConnectStatus(
  state: ConnectState.complete,
  payoutsEnabled: true,
  detailsSubmitted: true,
);

class _FakeConnectRepo implements ConnectRepository {
  _FakeConnectRepo({ConnectStatus? initial, this.onboardError})
    : current = initial ?? _notStarted;

  ConnectStatus current;
  final String onboardUrl = 'https://connect.stripe.com/setup/e/acct_1/abc';
  final Object? onboardError;
  bool onboardCalled = false;

  @override
  String Function() get newIdempotencyKey =>
      () => 'k';

  @override
  Future<ConnectStatus> fetchStatus() async => current;

  @override
  Future<String> startOnboarding() async {
    onboardCalled = true;
    if (onboardError != null) throw onboardError!;
    return onboardUrl;
  }
}

ProviderContainer _container(_FakeConnectRepo repo, {UrlOpener? opener}) {
  final container = ProviderContainer(
    overrides: [
      connectRepositoryProvider.overrideWithValue(repo),
      if (opener != null) urlOpenerProvider.overrideWithValue(opener),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ConnectStatus model', () {
    test('fromApi maps known + unknown states', () {
      expect(ConnectState.fromApi('NOT_STARTED'), ConnectState.notStarted);
      expect(ConnectState.fromApi('PENDING'), ConnectState.pending);
      expect(ConnectState.fromApi('COMPLETE'), ConnectState.complete);
      expect(ConnectState.fromApi('RESTRICTED'), ConnectState.restricted);
      expect(ConnectState.fromApi('SOMETHING_NEW'), ConnectState.unknown);
      expect(ConnectState.fromApi(null), ConnectState.unknown);
    });

    test('fromJson + status getters', () {
      final s = ConnectStatus.fromJson(const {
        'status': 'COMPLETE',
        'payoutsEnabled': true,
        'detailsSubmitted': true,
      });
      expect(s.isComplete, isTrue);
      expect(s.needsSetup, isFalse);
      expect(s.payoutsEnabled, isTrue);

      const pending = ConnectStatus(
        state: ConnectState.pending,
        payoutsEnabled: false,
        detailsSubmitted: false,
      );
      expect(pending.isPending, isTrue);
      expect(pending.needsSetup, isTrue);
    });

    test('fromJson tolerates missing fields', () {
      final s = ConnectStatus.fromJson(const {});
      expect(s.state, ConnectState.unknown);
      expect(s.payoutsEnabled, isFalse);
      expect(s.detailsSubmitted, isFalse);
    });
  });

  group('ConnectStatusController', () {
    test('build loads the current Connect status', () async {
      final container = _container(_FakeConnectRepo(initial: _complete));

      final status = await container.read(connectStatusProvider.future);

      expect(status.isComplete, isTrue);
    });

    test(
      'beginOnboarding fetches a link and opens it in the browser',
      () async {
        Uri? opened;
        final repo = _FakeConnectRepo();
        final container = _container(repo, opener: (uri) async => opened = uri);
        await container.read(connectStatusProvider.future);

        await container.read(connectStatusProvider.notifier).beginOnboarding();

        expect(repo.onboardCalled, isTrue);
        expect(opened.toString(), repo.onboardUrl);
      },
    );

    test('beginOnboarding surfaces failures as AppError', () async {
      final repo = _FakeConnectRepo(onboardError: Exception('boom'));
      final container = _container(repo, opener: (_) async {});
      await container.read(connectStatusProvider.future);

      await expectLater(
        container.read(connectStatusProvider.notifier).beginOnboarding(),
        throwsA(isA<AppError>()),
      );
    });

    test(
      'refresh re-fetches so a completed onboarding flips the state',
      () async {
        final repo = _FakeConnectRepo(initial: _notStarted);
        final container = _container(repo);
        final first = await container.read(connectStatusProvider.future);
        expect(first.isNotStarted, isTrue);

        repo.current = _complete; // as if the tasker finished at Stripe
        await container.read(connectStatusProvider.notifier).refresh();

        expect(
          container.read(connectStatusProvider).requireValue.isComplete,
          isTrue,
        );
      },
    );
  });
}
