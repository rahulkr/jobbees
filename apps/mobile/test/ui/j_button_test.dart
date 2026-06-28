import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/theme/colors.dart';
import 'package:jobbees_mobile/ui/ui.dart';

/// Finds a [DecoratedBox] whose fill is the given gradient.
Finder _withGradient(Gradient gradient) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient == gradient,
);

Future<void> _pump(WidgetTester tester, Widget button) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: button)),
  ),
);

void main() {
  testWidgets('primary button = honey-gold base + top sheen by default', (
    tester,
  ) async {
    await _pump(tester, JButton.primary(label: 'Post a job', onPressed: () {}));

    // Two-layer "lit from above" fill: the base gradient and the sheen overlay.
    expect(_withGradient(gradientPrimaryButton), findsOneWidget);
    expect(_withGradient(gradientButtonSheen), findsOneWidget);
  });

  testWidgets('primary button is flat when gradient: false', (tester) async {
    await _pump(
      tester,
      JButton.primary(label: 'Flat', onPressed: () {}, gradient: false),
    );

    expect(_withGradient(gradientPrimaryButton), findsNothing);
    expect(_withGradient(gradientButtonSheen), findsNothing);
  });

  testWidgets('disabled primary button is flat (no gradient)', (tester) async {
    await _pump(tester, JButton.primary(label: 'Disabled', onPressed: null));

    expect(_withGradient(gradientPrimaryButton), findsNothing);
  });

  testWidgets('secondary button stays flat (gradient is primary-only)', (
    tester,
  ) async {
    await _pump(tester, JButton.secondary(label: 'Later', onPressed: () {}));

    expect(_withGradient(gradientPrimaryButton), findsNothing);
  });
}
