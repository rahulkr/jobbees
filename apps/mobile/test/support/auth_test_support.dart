// Shared fakes for auth-dependent widget/unit tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobbees_mobile/core/auth/token_storage.dart';
import 'package:jobbees_mobile/features/auth/data/auth_repository.dart';
import 'package:jobbees_mobile/features/auth/models/auth_models.dart';
import 'package:jobbees_mobile/features/auth/providers/auth_controller.dart';

const testUser = UserProfile(
  id: 'user_test',
  email: 'jordan@example.com',
  firstName: 'Jordan',
  lastName: 'Lee',
  role: UserRole.client,
  emailVerified: true,
  phoneVerified: false,
);

/// An [AuthController] whose session state is fixed and whose [signUp] is
/// recorded — no network, no keychain.
class FakeAuthController extends AuthController {
  FakeAuthController({this.initialUser, this.signUpError, this.loginError});

  final UserProfile? initialUser;
  final Object? signUpError;
  final Object? loginError;
  int signUpCount = 0;
  int loginCount = 0;

  @override
  Future<UserProfile?> build() async => initialUser;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
  }) async {
    signUpCount++;
    if (signUpError != null) throw signUpError!;
    state = const AsyncData(testUser);
  }

  @override
  Future<void> login({required String email, required String password}) async {
    loginCount++;
    if (loginError != null) throw loginError!;
    state = const AsyncData(testUser);
  }
}

/// In-memory [TokenStorage] (skips the platform keychain).
class InMemoryTokenStorage implements TokenStorage {
  StoredTokens? _tokens;

  @override
  Future<StoredTokens?> read() async => _tokens;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    _tokens = (accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> clear() async => _tokens = null;
}

/// A scriptable [AuthRepository] fake.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signupTokens,
    this.loginTokens,
    this.refreshTokens,
    this.meUser,
  });

  final TokenPair? signupTokens;
  final TokenPair? loginTokens;
  final TokenPair? refreshTokens;
  final UserProfile? meUser;
  int logoutCount = 0;
  int refreshCount = 0;

  @override
  String Function() get newIdempotencyKey =>
      () => 'test-idempotency-key';

  @override
  Future<TokenPair?> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
  }) async => signupTokens;

  @override
  Future<TokenPair?> login({
    required String email,
    required String password,
  }) async => loginTokens;

  @override
  Future<TokenPair?> refresh(String? refreshToken) async {
    refreshCount++;
    return refreshTokens;
  }

  @override
  Future<UserProfile> fetchMe() async {
    final user = meUser;
    if (user == null) throw StateError('no session');
    return user;
  }

  @override
  Future<void> logout(String? refreshToken) async => logoutCount++;
}

/// Overrides for a signed-in app (home reachable, no network/keychain).
List<Override> signedInOverrides() => [
  authControllerProvider.overrideWith(
    () => FakeAuthController(initialUser: testUser),
  ),
];
