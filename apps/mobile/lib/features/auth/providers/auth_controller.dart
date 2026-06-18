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
import '../models/auth_models.dart';
import 'auth_providers.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);

class AuthController extends AsyncNotifier<UserProfile?> {
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

    try {
      return await ref.read(authRepositoryProvider).fetchMe();
    } catch (_) {
      // Stored access token expired or invalid. Silent refresh lands with the
      // login screen PR; for now a failed probe means signed out.
      await _clearLocal();
      return null;
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
}
