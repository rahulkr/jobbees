/// Widgetbook entry point.
///
/// Run with:
///   flutter run -t widgetbook/main.dart -d chrome
///
/// Add a new component page in widgetbook/components/<category>/j_<name>_page.dart,
/// then import + register below.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:jobbees_mobile/theme/app_theme.dart';

// Component pages — add new ones here as you create them.
import 'components/buttons/j_button_page.dart';
import 'components/inputs/j_text_field_page.dart';
import 'components/containers/j_card_page.dart';
import 'components/containers/j_bottom_sheet_page.dart';
import 'components/feedback/j_empty_state_page.dart';
import 'components/showcase/home_feed_page.dart';

void main() {
  runApp(const _WidgetbookApp());
}

@widgetbook.App()
class _WidgetbookApp extends StatelessWidget {
  const _WidgetbookApp();

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        ThemeAddon<ThemeData>(
          themes: [
            WidgetbookTheme(name: 'Light', data: JobbeesTheme.light()),
            WidgetbookTheme(name: 'Dark', data: JobbeesTheme.dark()),
          ],
          themeBuilder: (context, theme, child) =>
              Theme(data: theme, child: child),
        ),
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.ios.iPhoneSE,
            Devices.android.samsungGalaxyS20,
            Devices.ios.iPad,
          ],
        ),
        TextScaleAddon(min: 1.0, max: 2.0),
        LocalizationAddon(
          locales: const [Locale('en', 'AU')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ],
      directories: [
        WidgetbookCategory(name: 'Showcase', children: [homeFeedShowcase()]),
        WidgetbookCategory(
          name: 'Components',
          children: [
            WidgetbookFolder(name: 'Buttons', children: [jButtonPage()]),
            WidgetbookFolder(name: 'Inputs', children: [jTextFieldPage()]),
            WidgetbookFolder(
              name: 'Containers',
              children: [jCardPage(), jBottomSheetPage()],
            ),
            WidgetbookFolder(name: 'Feedback', children: [jEmptyStatePage()]),
          ],
        ),
      ],
    );
  }
}
