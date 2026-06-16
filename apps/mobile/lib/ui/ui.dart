/// Single import for the entire JOBBees UI layer.
///
/// Usage:
///   import 'package:jobbees_mobile/ui/ui.dart';
///
///   JButton.primary(label: 'Post a job', onPressed: () => ...)
///   JCard(child: Text('hello'))
///   JEmptyState(icon: ..., title: ..., body: ...)
library;

// Tokens
export 'tokens/tokens.dart';

// Platform helpers
export 'platform/j_haptics.dart';

// Components — buttons
export 'components/buttons/j_button.dart';

// Components — inputs
export 'components/inputs/j_text_field.dart';

// Components — containers
export 'components/containers/j_card.dart';
export 'components/containers/j_bottom_sheet.dart';

// Components — feedback
export 'components/feedback/j_empty_state.dart';
