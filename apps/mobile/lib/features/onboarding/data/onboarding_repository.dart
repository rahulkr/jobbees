// ignore_for_file: public_member_api_docs

/// Local persistence for onboarding milestones.
///
/// First-launch-only surfaces (the splash branding moment + the welcome
/// carousel, inventory rows 1 and 527) must not reappear on later launches.
/// We keep that flag on-device only — it's not account state, so it lives in
/// `shared_preferences` (→ `localStorage` on web) rather than the backend.
library;

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Versioned so a future onboarding revamp can re-show the carousel to
  /// everyone by bumping the suffix, without clashing with the retired flag.
  static const String _welcomeSeenKey = 'onboarding.welcome_seen.v1';

  bool get hasSeenWelcome => _prefs.getBool(_welcomeSeenKey) ?? false;

  Future<void> markWelcomeSeen() => _prefs.setBool(_welcomeSeenKey, true);
}
