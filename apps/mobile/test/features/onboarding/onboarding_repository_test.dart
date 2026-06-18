import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'hasSeenWelcome defaults to false and persists after markWelcomeSeen',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = OnboardingRepository(prefs);

      expect(repo.hasSeenWelcome, isFalse);

      await repo.markWelcomeSeen();

      expect(repo.hasSeenWelcome, isTrue);
      // A fresh repository over the same store still sees the flag.
      expect(OnboardingRepository(prefs).hasSeenWelcome, isTrue);
    },
  );
}
