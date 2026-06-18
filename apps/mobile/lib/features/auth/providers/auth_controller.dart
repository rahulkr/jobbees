// ignore_for_file: public_member_api_docs

/// App-wide session state and the auth actions that mutate it (ADR 009 — no
/// codegen).
///
/// `state` is an [AsyncValue<UserProfile?>]:
///  - `loading` ONLY during the initial session-restore probe at startup (the
///    router holds on splash while this resolves);
///  - `data(null)` signed out; `data(user)` signed in.
///
/// Auth actions ([signUp], [logout]) deliberately do NOT flip `state` back to
/// `loading` — that's reserved for restore — so the router doesn't mistake an
/// in-flight signup for a cold-start probe. Form-local progress is the screen's
/// concern; failures are rethrown as [AppError] for the screen to render.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_token.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/error_mapper.dart';
import '../data/social_auth_service.dart';
import '../models/auth_models.dart';
import 'auth_providers.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

class AuthController extends AsyncNotifier<UserProfile?> {
  /// In-flight refresh, shared so concurrent 401s trigger a single round-trip
  /// (single-flight). Reset when it settles.
  Future<bool>? _refreshing;

  @override
  Future<UserProfile?> build() async {
    // Restore a mobile session from the keychain (no-op/null on web, which
    // relies on cookies — we still probe /me so a live cookie session resumes).
    // Kept exception-free so a keychain hiccup degrades to "signed out" rather
    // than wedging startup.
    StoredTokens? stored;
    try {
      stored = await ref.read(tokenStorageProvider).read();
    } catch (_) {
      stored = null;
    }

    if (stored != null) {
      ref.read(accessTokenProvider.notifier).set(stored.accessToken);
    } else if (!kIsWeb) {
      return null;
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      return await repo.fetchMe();
    } catch (_) {
      // Stored access token likely expired — try one refresh before giving up
      // (15-min access tokens mean returning users almost always land here).
      if (await _tryRefresh(stored?.refreshToken)) {
        try {
          return await repo.fetchMe();
        } catch (_) {
          /* fall through to signed-out */
        }
      }
      await _clearLocal();
      return null;
    }
  }

  /// Refreshes the session, coalescing concurrent callers onto one request.
  /// Returns true if a fresh access token is now in place. On failure the
  /// session is cleared and `state` flips to signed-out.
  Future<bool> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final stored = await _safeRead();
    return _tryRefresh(stored?.refreshToken, signOutOnFailure: true);
  }

  Future<bool> _tryRefresh(
    String? refreshToken, {
    bool signOutOnFailure = false,
  }) async {
    // Mobile needs a stored refresh token; web sends none (cookie-based).
    if (!kIsWeb && refreshToken == null) {
      if (signOutOnFailure) await _signOut();
      return false;
    }
    try {
      final tokens = await ref
          .read(authRepositoryProvider)
          .refresh(refreshToken);
      await _persist(tokens);
      return true;
    } catch (_) {
      if (signOutOnFailure) await _signOut();
      return false;
    }
  }

  Future<void> _signOut() async {
    await _clearLocal();
    state = const AsyncData(null);
  }

  /// Google sign-in: opens the provider sheet, exchanges the ID token for a
  /// session. A cancelled sheet is a no-op (no error); a genuine failure throws
  /// [AppError] for the screen to render. [role] applies only on first signup.
  Future<void> signInWithGoogle({UserRole? role}) => _social(
    () => ref.read(socialAuthServiceProvider).signInWithGoogle(),
    role,
  );

  Future<void> signInWithApple({UserRole? role}) => _social(
    () => ref.read(socialAuthServiceProvider).signInWithApple(),
    role,
  );

  Future<void> _social(
    Future<SocialCredential?> Function() getCredential,
    UserRole? role,
  ) async {
    try {
      final credential = await getCredential();
      if (credential == null) return; // user cancelled — nothing to do
      final repo = ref.read(authRepositoryProvider);
      final tokens = await repo.oauthLogin(
        provider: credential.provider,
        idToken: credential.idToken,
        firstName: credential.firstName,
        lastName: credential.lastName,
        role: role,
      );
      await _persist(tokens);
      state = AsyncData(await repo.fetchMe());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final tokens = await repo.login(email: email, password: password);
      await _persist(tokens);
      state = AsyncData(await repo.fetchMe());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    UserRole? role,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final tokens = await repo.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      await _persist(tokens);
      state = AsyncData(await repo.fetchMe());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Upgrades the current client account to a tasker (one-way). Refreshes the
  /// session so the new role lands in the access token (TASKER-only endpoints
  /// reject a stale CLIENT token), then refetches the profile so `state` carries
  /// the tasker role and the router/UI react.
  Future<void> becomeTasker() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.becomeTasker();
      await refreshSession();
      state = AsyncData(await repo.fetchMe());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> logout() async {
    final stored = await ref.read(tokenStorageProvider).read();
    try {
      await ref.read(authRepositoryProvider).logout(stored?.refreshToken);
    } catch (_) {
      // Best-effort server revoke; always clear locally regardless.
    }
    await _clearLocal();
    state = const AsyncData(null);
  }

  Future<void> _persist(TokenPair? tokens) async {
    if (tokens == null) return; // web: server set HttpOnly cookies
    ref.read(accessTokenProvider.notifier).set(tokens.accessToken);
    await ref
        .read(tokenStorageProvider)
        .write(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
  }

  Future<void> _clearLocal() async {
    ref.read(accessTokenProvider.notifier).clear();
    await ref.read(tokenStorageProvider).clear();
  }

  Future<StoredTokens?> _safeRead() async {
    try {
      return await ref.read(tokenStorageProvider).read();
    } catch (_) {
      return null;
    }
  }
}
