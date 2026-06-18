// ignore_for_file: public_member_api_docs

/// Wraps the native Google / Apple sign-in SDKs and hands back a normalised
/// [SocialCredential] (a provider ID token, plus the name where the SDK gives
/// one). Everything above this — repository, controller, UI, tests — depends on
/// the [SocialAuthService] interface, so the SDK detail lives in exactly one
/// place ([RealSocialAuthService]) and is swappable with a fake in tests.
///
/// Client IDs are public identifiers (not secrets): the iOS client ID lives in
/// Info.plist (GIDClientID); the web client ID below is passed as
/// `serverClientId` so the issued ID token's audience matches an entry in the
/// API's GOOGLE_OAUTH_CLIENT_IDS allow-list (ADR 006 / social-login setup).
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/network/error_mapper.dart';

@immutable
class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.firstName,
    this.lastName,
  });

  /// 'google' | 'apple' — the `:provider` path segment on /auth/oauth.
  final String provider;
  final String idToken;
  final String? firstName;
  final String? lastName;
}

abstract class SocialAuthService {
  /// Returns the credential, or null if the user cancelled the sheet. Throws
  /// [AppError] on a genuine failure.
  Future<SocialCredential?> signInWithGoogle();

  Future<SocialCredential?> signInWithApple();
}

class RealSocialAuthService implements SocialAuthService {
  RealSocialAuthService();

  /// Web OAuth 2.0 client ID (public). Override at build time with
  /// `--dart-define=GOOGLE_WEB_CLIENT_ID=...`; default is the project's client.
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '594004108083-d34g05filuur5u3vbf2hra8917c7g0r8.apps.googleusercontent.com',
  );

  late final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _googleWebClientId,
  );

  @override
  Future<SocialCredential?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null; // user dismissed the sheet
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const AppError('Google sign-in failed. Please try again.');
    }
    final (first, last) = _splitName(account.displayName);
    return SocialCredential(
      provider: 'google',
      idToken: idToken,
      firstName: first,
      lastName: last,
    );
  }

  @override
  Future<SocialCredential?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppError('Apple sign-in failed. Please try again.');
      }
      // Apple returns the name only on the FIRST authorization; persist it now.
      return SocialCredential(
        provider: 'apple',
        idToken: idToken,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      throw const AppError('Apple sign-in failed. Please try again.');
    }
  }

  /// Google gives a single display name; split into first / last for the API.
  (String?, String?) _splitName(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return (null, null);
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, null);
    return (parts.first, parts.sublist(1).join(' '));
  }
}
