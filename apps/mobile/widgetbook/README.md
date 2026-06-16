# JOBBees Widgetbook

Visual catalog of every component in the JOBBees Flutter UI layer (`apps/mobile/lib/ui/`).

## Why

When the AI (or you) is about to build a new component, the first question should be: "do we already have this?" Widgetbook is the answer.

- One page per component, showing every state (idle / pressed / loading / disabled / error / empty)
- Light + dark mode side-by-side
- Multiple device frames (iPhone 15, Pixel 8, iPad Mini, browser desktop)
- Hot-reload as you edit components

Without this, by Sprint 6 the codebase has 3 slightly-different "Confirm" buttons because no one knew the others existed.

## Running it

```bash
cd apps/mobile
flutter run -t widgetbook/main.dart -d chrome    # web (easiest review)
flutter run -t widgetbook/main.dart -d "iPhone"  # iOS sim
flutter run -t widgetbook/main.dart -d emulator  # Android
```

The web target is the easiest for reviewing — open it in a regular browser, no simulator needed.

## Adding a component story

Every component in `apps/mobile/lib/ui/components/<category>/j_<name>.dart` MUST have a Widgetbook page at `apps/mobile/widgetbook/components/<category>/j_<name>_page.dart`.

The page must show:

1. **Default state** — what the component looks like with default props
2. **Every variant** — primary / secondary / danger / ghost (or whatever the component has)
3. **Every state** — idle / pressed / disabled / loading / error
4. **Edge cases** — empty content, very long content, RTL if applicable
5. **A "use it" example** — a small fully-formed example showing how it composes with other components

Template lives in `apps/mobile/widgetbook/_template_page.dart`.

## Conventions

- One file per component story
- Filename: `j_<component_name>_page.dart`
- Inside, export a `Widget` named `j<ComponentName>Page` (camelCase)
- Group by component category (buttons / inputs / containers / feedback / data / navigation)
- Use `Center` + `Padding(JSpacing.base)` to frame the demo so it's not flush against the device edge

## Light + dark mode

Widgetbook's theme addon switches between light and dark `ThemeData`. Both are built in `apps/mobile/lib/theme/app_theme.dart`. Every component must render correctly in both — if dark mode breaks, that's a real bug not a future-problem.

## Device frames

The Widgetbook addon shows the same component in multiple device frames simultaneously. Verify:

- Components don't overflow on iPhone SE (smallest supported)
- Tap targets stay ≥ 44px on every device
- Layouts adapt to wider screens (iPad / browser)

## CI integration

The visual regression tests (per S2 + S11 a11y audit) screenshot every Widgetbook page on every PR. If a screenshot diff appears, the PR fails until you either:

- Accept the diff (intentional change) → `flutter test --update-goldens`
- Fix the regression

This is the single best defense against the AI accidentally breaking 5 screens when editing 1.

## What this folder is NOT

- Not the production app entry point — that's `apps/mobile/lib/main.dart`
- Not a place for full screens — screens live in `apps/mobile/lib/features/<feature>/` and are tested via integration tests
- Not a Storybook for the Next.js admin — that's `apps/admin/storybook/`

It's a component catalog. Just components.
