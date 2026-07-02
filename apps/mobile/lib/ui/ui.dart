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
export 'platform/j_pressable.dart';

// Components — buttons
export 'components/buttons/j_button.dart';

// Components — inputs
export 'components/inputs/j_text_field.dart';
export 'components/inputs/j_otp_field.dart';

// Motion
export 'motion/j_entrance.dart';

// Components — keyboard
export 'components/keyboard/dismiss_keyboard.dart';

// Components — containers
export 'components/containers/j_avatar.dart';
export 'components/containers/j_card.dart';
export 'components/containers/j_bottom_sheet.dart';

// Components — navigation
export 'components/navigation/j_app_bar.dart';
export 'components/navigation/j_bottom_nav.dart';

// Components — feedback
export 'components/feedback/j_empty_state.dart';
export 'components/feedback/j_hero_mark.dart';
export 'components/feedback/j_loading_skeleton.dart';
export 'components/feedback/j_snackbar.dart';
