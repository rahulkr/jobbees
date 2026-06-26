import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobbees_mobile/ui/ui.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps [child] in a MaterialApp, optionally flipping reduced-motion on while
/// preserving the default test MediaQuery (size etc.).
Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('JSkeleton.box renders at the requested size', (tester) async {
    await tester.pumpWidget(_wrap(const JSkeleton.box(width: 120, height: 40)));

    final size = tester.getSize(find.byType(JSkeleton));
    expect(size.width, 120);
    expect(size.height, 40);
  });

  testWidgets('JSkeleton.circle is square', (tester) async {
    await tester.pumpWidget(_wrap(const JSkeleton.circle(size: 48)));

    final size = tester.getSize(find.byType(JSkeleton));
    expect(size, const Size(48, 48));
  });

  testWidgets('JShimmer animates by default', (tester) async {
    await tester.pumpWidget(
      _wrap(const JShimmer(child: JSkeleton.box(height: 20))),
    );
    // One frame only — never pumpAndSettle a shimmer (its sweep repeats).
    await tester.pump();

    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(JSkeleton), findsOneWidget);
  });

  testWidgets('JShimmer is static (no sweep) under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const JShimmer(child: JSkeleton.box(height: 20)),
        reduceMotion: true,
      ),
    );
    // Safe to settle: no animation is scheduled in reduced-motion mode.
    await tester.pumpAndSettle();

    expect(find.byType(Shimmer), findsNothing);
    expect(find.byType(JSkeleton), findsOneWidget);
  });
}
