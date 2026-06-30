// ignore_for_file: public_member_api_docs

/// Biometric re-login wiring (inventory rows 9 / 235, Lean): the service, the
/// on-device "enabled" flag, and the app-lock state the router gates on.
/// ADR 009 — Notifier/Provider, no codegen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../onboarding/providers/onboarding_providers.dart'
    show sharedPreferencesProvider;
import '../data/biometric_auth_service.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>(
  (ref) => RealBiometricAuthService(),
);

/// Whether the device can do biometrics right now (supported + enrolled).
/// Resolves to false on web / unsupported devices, so the profile toggle hides
/// itself rather than offering an unusable switch.
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.read(biometricAuthServiceProvider).isAvailable(),
);

/// On-device flag: has the user turned biometric unlock on? Device-global and
/// not account state, so it lives in `shared_preferences` (→ localStorage on
/// web) like the onboarding "seen" flag — not the backend.
class BiometricEnabledNotifier extends Notifier<bool> {
  /// Versioned so a future change can reset everyone without clashing.
  static const String _key = 'auth.biometric_enabled.v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() => _prefs.getBool(_key) ?? false;

  Future<void> set({required bool enabled}) async {
    await _prefs.setBool(_key, enabled);
    state = enabled;
  }
}

final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledNotifier, bool>(
      BiometricEnabledNotifier.new,
    );

/// Whether the app is currently locked behind the biometric prompt. Armed once
/// at startup from [biometricEnabledProvider] (read, not watched — enabling
/// biometrics mid-session must not lock the current session), and cleared by a
/// successful unlock or the password fallback. The router routes a locked,
/// authenticated session to `/unlock` (CLAUDE.md rule 5 — the screen never
/// navigates itself).
class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(biometricEnabledProvider);

  void unlock() => state = false;
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(
  AppLockNotifier.new,
);
