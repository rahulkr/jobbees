import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/auth/auth_token.dart';
import 'package:jobbees_mobile/features/auth/data/auth_repository.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_providers.dart';

import '../../support/auth_test_support.dart';

/// Repo whose `/me` fails until a refresh swaps in a fresh token — exercises the
/// startup refresh fallback and single-flight coalescing.
class _ScriptedRepo implements AuthRepository {
  _ScriptedRepo({
    required this.refreshTokens,
    required this.meAfterRefresh,
    this.refreshDelay = Duration.zero,
    bool initiallyAuthenticated = false,
  }) : _refreshed = initiallyAuthenticated;

  final TokenPair? refreshTokens;
  final UserProfile meAfterRefresh;
  final Duration refreshDelay;
  int refreshCount = 0;
  bool _refreshed;

  @override
  String Function() get newIdempotencyKey =>
      () => 'k';

  @override
  Future<UserProfile> fetchMe() async {
    if (!_refreshed) throw StateError('401');
    return meAfterRefresh;
  }

  @override
  Future<TokenPair?> refresh(String? refreshToken) async {
    refreshCount++;
    if (refreshDelay > Duration.zero) await Future<void>.delayed(refreshDelay);
    _refreshed = true;
    return refreshTokens;
  }

  @override
  Future<TokenPair?> login({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<TokenPair?> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
  }) async => null;

  @override
  Future<void> logout(String? refreshToken) async {}
}

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

  test('login persists tokens and authenticates', () async {
    final storage = InMemoryTokenStorage();
    final container = _container(
      repo: FakeAuthRepository(
        loginTokens: const TokenPair(
          accessToken: 'access-2',
          refreshToken: 'refresh-2',
        ),
        meUser: testUser,
      ),
      storage: storage,
    );
    await container.read(authControllerProvider.future);

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'jordan@example.com', password: 'a-strong-passphrase');

    expect(container.read(authControllerProvider).valueOrNull, testUser);
    expect(container.read(accessTokenProvider), 'access-2');
    expect((await storage.read())!.refreshToken, 'refresh-2');
  });

  test('build refreshes when the stored access token is rejected', () async {
    final storage = InMemoryTokenStorage()
      ..write(accessToken: 'expired', refreshToken: 'refresh-1');
    // /me throws until a refresh swaps in a fresh access token.
    final repo = _ScriptedRepo(
      refreshTokens: const TokenPair(
        accessToken: 'access-new',
        refreshToken: 'refresh-new',
      ),
      meAfterRefresh: testUser,
    );
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    final user = await container.read(authControllerProvider.future);

    expect(user, testUser);
    expect(repo.refreshCount, 1);
    expect((await storage.read())!.accessToken, 'access-new');
  });

  test(
    'refreshSession coalesces concurrent callers into one refresh',
    () async {
      final storage = InMemoryTokenStorage()
        ..write(accessToken: 'a', refreshToken: 'refresh-1');
      final repo = _ScriptedRepo(
        refreshTokens: const TokenPair(
          accessToken: 'access-new',
          refreshToken: 'refresh-new',
        ),
        meAfterRefresh: testUser,
        refreshDelay: const Duration(milliseconds: 20),
        initiallyAuthenticated: true, // build() succeeds without a refresh
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          tokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final notifier = container.read(authControllerProvider.notifier);

      final results = await Future.wait([
        notifier.refreshSession(),
        notifier.refreshSession(),
        notifier.refreshSession(),
      ]);

      expect(results, everyElement(isTrue));
      expect(repo.refreshCount, 1); // single-flight
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
