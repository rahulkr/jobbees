import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/core/observability/error_reporting.dart';

void main() {
  test('disabled without a DSN, and the app still runs', () async {
    // Tests build with no --dart-define=SENTRY_DSN, so reporting is off.
    expect(errorReportingEnabled, isFalse);

    var ran = false;
    await initErrorReporting(() {
      ran = true;
    });

    expect(ran, isTrue);
  });
}
