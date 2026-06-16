/// Template for adding a new Widgetbook component page.
///
/// Copy this file to widgetbook/components/<category>/j_<name>_page.dart,
/// rename the function + class, fill in the use cases, then register in main.dart.

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent jTemplatePage() {
  return WidgetbookComponent(
    name: 'JTemplate',  // Change to component name
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => _frame(
          const Placeholder(),  // Replace with the component
        ),
      ),
      // Add more use cases — every variant, every state
      // WidgetbookUseCase(name: 'Variant: Primary', builder: ...),
      // WidgetbookUseCase(name: 'State: Loading', builder: ...),
      // WidgetbookUseCase(name: 'State: Disabled', builder: ...),
      // WidgetbookUseCase(name: 'Edge case: Very long content', builder: ...),
    ],
  );
}

/// Standard frame for component pages — centred with brand padding.
/// Use this in every use case for consistency.
Widget _frame(Widget child) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Center(child: child),
  );
}
