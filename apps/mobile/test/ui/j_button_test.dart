import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/theme/colors.dart';
import 'package:jobbees_mobile/ui/ui.dart';

/// Matches the button's gradient fill layer (a [DecoratedBox] with a gradient).
Finder _gradientFill() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient != null,
);

Future<void> _pump(WidgetTester tester, Widget button) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: button)),
  ),
);

void main() {
  testWidgets('primary button fills with the depth gradient by default', (
    tester,
  ) async {
    await _pump(tester, JButton.primary(label: 'Post a job', onPressed: () {}));

    expect(_gradientFill(), findsOneWidget);
    final box = tester.widget<DecoratedBox>(_gradientFill());
    expect((box.decoration as BoxDecoration).gradient, gradientPrimaryButton);
  });

  testWidgets('primary button is flat when gradient: false', (tester) async {
    await _pump(
      tester,
      JButton.primary(label: 'Flat', onPressed: () {}, gradient: false),
    );

    expect(_gradientFill(), findsNothing);
  });

  testWidgets('disabled primary button is flat (no gradient)', (tester) async {
    await _pump(tester, JButton.primary(label: 'Disabled', onPressed: null));

    expect(_gradientFill(), findsNothing);
  });

  testWidgets('secondary button stays flat (gradient is primary-only)', (
    tester,
  ) async {
    await _pump(tester, JButton.secondary(label: 'Later', onPressed: () {}));

    expect(_gradientFill(), findsNothing);
  });
}
