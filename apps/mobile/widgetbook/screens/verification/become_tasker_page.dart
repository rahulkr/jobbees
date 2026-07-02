/// Widgetbook page for the Become-a-tasker screen.
///
/// Renders the initial (unsubmitted) state so the entrance choreography and
/// step-list composition can be reviewed. Tapping "Get started" in the harness
/// will attempt to call the auth controller and gracefully fail — that's
/// expected without provider overrides.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/features/verification/screens/become_tasker_screen.dart';

WidgetbookComponent becomeTaskerPage() {
  return WidgetbookComponent(
    name: 'Become a tasker',
    useCases: [
      WidgetbookUseCase(
        name: 'Intro (unsubmitted)',
        builder: (ctx) => const ProviderScope(child: BecomeTaskerScreen()),
      ),
    ],
  );
}
