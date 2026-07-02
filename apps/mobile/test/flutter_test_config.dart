import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cross-platform golden tolerance.
///
/// Golden reference images are generated locally (macOS) but CI renders on
/// Linux. Even with the same bundled fonts (Inter + Lucide), the two platforms'
/// rasterisers produce small sub-pixel antialiasing differences — observed
/// ~2.1% on the social-button pair and ~1.8% on the shell — which the default
/// exact-match comparator rejects, failing CI on visually-identical output.
///
/// This tolerance absorbs that antialiasing noise while still catching real
/// layout / content regressions, which diff far above it (a screen redesign is
/// tens of percent). Keep the bound meaningful by regenerating goldens whenever
/// a screen legitimately changes: `flutter test --update-goldens`.
const double _kGoldenDiffTolerance = 0.05;

/// Auto-loaded by `flutter test` for every test under `test/`. Swaps the default
/// [LocalFileComparator] for a tolerant one; non-golden tests are unaffected.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final GoldenFileComparator previous = goldenFileComparator;
  if (previous is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(previous.basedir);
  }
  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  // [LocalFileComparator] derives its basedir from the *directory* of the test
  // file URI it is given. `basedir` already ends in `/`, so resolving a sentinel
  // filename against it keeps golden lookups rooted at the same directory.
  _TolerantGoldenComparator(Uri basedir)
    : super(basedir.resolve('flutter_test_config.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _kGoldenDiffTolerance) {
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
