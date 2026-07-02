/// Widgetbook page for the Splash screen.
///
/// Renders the screen inside a phone-shaped frame at typical device sizes.
/// The router-side hand-off (splashCompleteProvider) fires on the 1.5s timer;
/// while the harness will emit a "no listeners" state error, the visual entry
/// choreography (mark scale-in, tagline slide-up) is what this page is here to
/// review.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/features/onboarding/screens/splash_screen.dart';

WidgetbookComponent splashPage() {
  return WidgetbookComponent(
    name: 'Splash',
    useCases: [
      WidgetbookUseCase(
        name: 'Cold launch',
        builder: (ctx) => const ProviderScope(child: SplashScreen()),
      ),
    ],
  );
}
