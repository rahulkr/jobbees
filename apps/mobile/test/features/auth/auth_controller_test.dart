import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/auth/auth_token.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_providers.dart';

import '../../support/auth_test_support.dart';

ProviderContainer _container({
  required FakeAuthRepository repo,
  required InMemoryTokenStorage storage,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStorageProvider.overrideWithValue(storage),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'build restores a signed-out session when no tokens are stored',
    () async {
      final container = _container(
        repo: FakeAuthRepository(meUser: testUser),
        storage: InMemoryTokenStorage(),
      );

      final user = await container.read(authControllerProvider.future);

      expect(user, isNull); // nothing in storage → signed out (mobile)
    },
  );

  test(
    'signUp persists tokens, sets the bearer token, and authenticates',
    () async {
      final storage = InMemoryTokenStorage();
      final container = _container(
        repo: FakeAuthRepository(
          signupTokens: const TokenPair(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
          ),
          meUser: testUser,
        ),
        storage: storage,
      );
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .signUp(
            email: 'jordan@example.com',
            password: 'a-strong-passphrase',
            firstName: 'Jordan',
            lastName: 'Lee',
          );

      expect(container.read(authControllerProvider).valueOrNull, testUser);
      expect(container.read(accessTokenProvider), 'access-1');
      expect((await storage.read())!.refreshToken, 'refresh-1');
    },
  );

  test('logout clears storage, bearer token, and session', () async {
    final storage = InMemoryTokenStorage()
      ..write(accessToken: 'a', refreshToken: 'r');
    final repo = FakeAuthRepository(meUser: testUser);
    final container = _container(repo: repo, storage: storage);
    await container.read(authControllerProvider.future);
    container.read(accessTokenProvider.notifier).set('a');

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(authControllerProvider).valueOrNull, isNull);
    expect(container.read(accessTokenProvider), isNull);
    expect(await storage.read(), isNull);
    expect(repo.logoutCount, 1);
  });
}
