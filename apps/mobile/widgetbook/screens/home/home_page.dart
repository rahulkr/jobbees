/// Widgetbook page for the Home tab (Sprint 2 placeholder).
///
/// Shows the greeting header + the designed placeholder empty state. Real
/// feed replaces the placeholder in Sprint 3+; the header stays.
library;

import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/features/home/screens/home_screen.dart';

WidgetbookComponent homePage() {
  return WidgetbookComponent(
    name: 'Home tab',
    useCases: [
      WidgetbookUseCase(
        name: 'Placeholder (Sprint 2)',
        builder: (ctx) => const HomeScreen(),
      ),
    ],
  );
}
