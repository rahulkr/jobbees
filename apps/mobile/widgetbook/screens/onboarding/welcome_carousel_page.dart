/// Widgetbook page for the Welcome carousel.
///
/// Renders all three slides live — swipe or tap Next in the harness to move
/// between them and review the per-slide entrance choreography + breathing
/// icon.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/features/onboarding/screens/welcome_carousel_screen.dart';

WidgetbookComponent welcomeCarouselPage() {
  return WidgetbookComponent(
    name: 'Welcome carousel',
    useCases: [
      WidgetbookUseCase(
        name: 'Three-slide walkthrough',
        builder: (ctx) => const ProviderScope(child: WelcomeCarouselScreen()),
      ),
    ],
  );
}
