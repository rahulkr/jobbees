// Shared fakes for auth-dependent widget/unit tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobbees_mobile/core/auth/token_storage.dart';
import 'package:jobbees_mobile/features/auth/data/auth_repository.dart';
import 'package:jobbees_mobile/features/auth/data/social_auth_service.dart';
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
  FakeAuthController({
    this.initialUser,
    this.signUpError,
    this.loginError,
    this.socialError,
    this.becomeTaskerError,
  });

  final UserProfile? initialUser;
  final Object? signUpError;
  final Object? loginError;
  final Object? socialError;
  final Object? becomeTaskerError;
  int signUpCount = 0;
  int loginCount = 0;
  int googleCount = 0;
  int appleCount = 0;
  int becomeTaskerCount = 0;

  @override
  Future<UserProfile?> build() async => initialUser;

  int reloadProfileCount = 0;

  @override
  Future<void> becomeTasker() async {
    becomeTaskerCount++;
    if (becomeTaskerError != null) throw becomeTaskerError!;
  }

  @override
  Future<void> reloadProfile() async => reloadProfileCount++;

  @override
  Future<void> signInWithGoogle({UserRole? role}) async {
    googleCount++;
    if (socialError != null) throw socialError!;
    state = const AsyncData(testUser);
  }

  @override
  Future<void> signInWithApple({UserRole? role}) async {
    appleCount++;
    if (socialError != null) throw socialError!;
    state = const AsyncData(testUser);
  }

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
    this.oauthTokens,
    this.meUser,
  });

  final TokenPair? signupTokens;
  final TokenPair? loginTokens;
  final TokenPair? refreshTokens;
  final TokenPair? oauthTokens;
  final UserProfile? meUser;
  int logoutCount = 0;
  int becomeTaskerCount = 0;
  int refreshCount = 0;
  int forgotCount = 0;
  int resendCount = 0;
  String? lastOAuthProvider;
  UserRole? lastOAuthRole;
  String? lastResetToken;
  String? lastVerifyToken;

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
  Future<TokenPair?> oauthLogin({
    required String provider,
    required String idToken,
    String? firstName,
    String? lastName,
    UserRole? role,
  }) async {
    lastOAuthProvider = provider;
    lastOAuthRole = role;
    return oauthTokens;
  }

  @override
  Future<void> verifyEmail(String token) async => lastVerifyToken = token;

  @override
  Future<void> resendVerificationEmail() async => resendCount++;

  @override
  Future<void> forgotPassword(String email) async => forgotCount++;

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    lastResetToken = token;
  }

  @override
  Future<void> becomeTasker() async => becomeTaskerCount++;

  @override
  Future<void> logout(String? refreshToken) async => logoutCount++;
}

/// A scriptable [SocialAuthService] — no native SDK.
class FakeSocialAuthService implements SocialAuthService {
  FakeSocialAuthService({this.google, this.apple, this.error});

  /// Credential to return; null models a cancelled provider sheet.
  final SocialCredential? google;
  final SocialCredential? apple;
  final Object? error;

  @override
  Future<SocialCredential?> signInWithGoogle() async {
    if (error != null) throw error!;
    return google;
  }

  @override
  Future<SocialCredential?> signInWithApple() async {
    if (error != null) throw error!;
    return apple;
  }
}

/// Overrides for a signed-in app (home reachable, no network/keychain).
List<Override> signedInOverrides() => [
  authControllerProvider.overrideWith(
    () => FakeAuthController(initialUser: testUser),
  ),
];
