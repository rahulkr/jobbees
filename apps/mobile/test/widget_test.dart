// Smoke tests for the Flutter Web foundation shell (FW-01..03).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/app.dart';
import 'package:jobbees_mobile/core/responsive/breakpoints.dart';

void main() {
  testWidgets('home screen renders and routes to a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JobbeesApp()));
    await tester.pumpAndSettle();

    expect(find.text('JOBBees'), findsOneWidget);
    expect(find.text('Post a job'), findsOneWidget);

    await tester.tap(find.text('Post a job'));
    await tester.pumpAndSettle();

    // go_router navigated to the placeholder route.
    expect(find.text('/post'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('compact layout drives a phone-shaped home body', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: JobbeesApp()));
    await tester.pumpAndSettle();

    expect(find.text('JOBBees'), findsOneWidget);
  });

  group('Breakpoints', () {
    test('classifies widths into window size classes', () {
      expect(Breakpoints.classify(390), WindowSizeClass.compact);
      expect(Breakpoints.classify(800), WindowSizeClass.medium);
      expect(Breakpoints.classify(1280), WindowSizeClass.expanded);
    });
  });
}
