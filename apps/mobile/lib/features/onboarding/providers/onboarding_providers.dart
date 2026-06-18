// ignore_for_file: public_member_api_docs

/// Riverpod wiring for onboarding (ADR 009 — Notifier/Provider, no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/onboarding_repository.dart';

/// Resolved once in `bootstrap()` and injected via [ProviderScope.overrides].
/// Reading it before that override throws on purpose — a missing override is a
/// wiring bug we want surfaced loudly at startup, not a silent default.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap()',
  ),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(sharedPreferencesProvider)),
);

/// Whether the welcome carousel has been seen. Seeds from disk, then flips to
/// true (and persists) when the user finishes or skips. The router watches
/// this to gate the first-run experience instead of screens pushing routes
/// (CLAUDE.md rule 5).
class WelcomeSeenNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingRepositoryProvider).hasSeenWelcome;

  Future<void> markSeen() async {
    if (state) return;
    await ref.read(onboardingRepositoryProvider).markWelcomeSeen();
    state = true;
  }
}

final welcomeSeenProvider = NotifierProvider<WelcomeSeenNotifier, bool>(
  WelcomeSeenNotifier.new,
);

/// Flips true once the splash branding moment has elapsed. Splash-gated
/// routing reads this rather than the splash widget navigating directly, so
/// the transition stays redirect-driven (CLAUDE.md rule 5).
class SplashCompleteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}

final splashCompleteProvider = NotifierProvider<SplashCompleteNotifier, bool>(
  SplashCompleteNotifier.new,
);
