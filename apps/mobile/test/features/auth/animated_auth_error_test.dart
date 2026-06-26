import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/features/auth/widgets/animated_auth_error.dart';
import 'package:jobbees_mobile/features/auth/widgets/auth_error_banner.dart';

void main() {
  Widget host(String? message) => MaterialApp(
    home: Scaffold(body: AnimatedAuthError(message: message)),
  );

  testWidgets('shows no banner when the message is null', (tester) async {
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();

    expect(find.byType(AuthErrorBanner), findsNothing);
  });

  testWidgets('surfaces the message when set', (tester) async {
    await tester.pumpWidget(host('Something went wrong'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('collapses again once the message clears', (tester) async {
    await tester.pumpWidget(host('Something went wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byType(AuthErrorBanner), findsNothing);
  });

  testWidgets('marks the error as a live region for assistive tech', (
    tester,
  ) async {
    await tester.pumpWidget(host('Something went wrong'));
    await tester.pumpAndSettle();

    final liveRegion = find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.liveRegion ?? false),
    );
    expect(liveRegion, findsOneWidget);
  });
}
