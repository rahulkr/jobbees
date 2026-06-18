// ignore_for_file: public_member_api_docs

/// Secure persistence for the mobile session tokens (ADR 006).
///
/// Mobile keeps the short-lived access token + opaque refresh token in the
/// platform keychain (iOS Keychain / Android Keystore). Web never uses this —
/// it relies on the API's HttpOnly `jb_access`/`jb_refresh` cookies — so every
/// method is a deliberate no-op on web rather than placing tokens in
/// JS-reachable storage (apps/mobile CLAUDE.md: never store tokens in
/// localStorage).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A persisted access + refresh token pair.
typedef StoredTokens = ({String accessToken, String refreshToken});

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'auth.access_token';
  static const String _refreshKey = 'auth.refresh_token';

  Future<StoredTokens?> read() async {
    if (kIsWeb) return null;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (kIsWeb) return;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
