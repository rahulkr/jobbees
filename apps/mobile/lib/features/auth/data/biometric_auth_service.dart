// ignore_for_file: public_member_api_docs

/// Wraps the native biometric SDK (`local_auth`) behind an interface so the
/// providers, unlock screen and tests depend on [BiometricAuthService], not the
/// plugin directly — the same fake-in-tests pattern as [SocialAuthService].
///
/// Both methods are exception-free: an unsupported device, no enrolled
/// biometrics, a cancelled or failed prompt, or a missing plugin (web / tests)
/// all resolve to `false` rather than throwing, so callers branch on a plain
/// bool.
library;

import 'package:local_auth/local_auth.dart';

abstract class BiometricAuthService {
  /// Whether the device supports biometrics and has at least one enrolled.
  Future<bool> isAvailable();

  /// Prompts for biometric auth. Returns true on success; false on
  /// failure / cancellation / unavailability. Never throws.
  Future<bool> authenticate({required String reason});
}

class RealBiometricAuthService implements BiometricAuthService {
  RealBiometricAuthService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      // Web / unsupported platform / missing plugin → treat as unavailable.
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
