import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/analytics/analytics.dart';

void main() {
  test('disabled without a key; every call is a safe no-op', () async {
    // Tests build with no --dart-define=POSTHOG_KEY.
    expect(Analytics.enabled, isFalse);

    // None of these touch the native plugin or throw when disabled.
    await Analytics.init();
    await Analytics.track('test_event', {'k': 'v'});
    await Analytics.identify('user_1');
    await Analytics.reset();
  });
}
