# Widgetbook install — one-time setup

Run these commands once to wire Widgetbook into the Flutter app. After this, the scaffolded files in `widgetbook/` will run.

## Add the dependencies

From `apps/mobile/`:

```bash
flutter pub add widgetbook
flutter pub add widgetbook_annotation
flutter pub add dev:widgetbook_generator
flutter pub add dev:build_runner
```

This updates `pubspec.yaml` and downloads:

- `widgetbook` — the rendering library
- `widgetbook_annotation` — the `@widgetbook.App()` annotation (optional but cleaner)
- `widgetbook_generator` — code-gen for the annotation (dev only)
- `build_runner` — runs the generator (dev only)

## Verify the entry point compiles

```bash
flutter run -t widgetbook/main.dart -d chrome
```

Should open a browser tab with the JOBBees Widgetbook — left-hand tree showing Components → Buttons / Inputs / Containers / Feedback.

If it fails on a missing AppTheme.dark() / AppTheme.light(), see the next section.

## Verify AppTheme has light + dark factories

Widgetbook expects `AppTheme.light()` and `AppTheme.dark()` factory methods returning ThemeData. The file `apps/mobile/lib/theme/app_theme.dart` was scaffolded in Sprint 0 — check it has both. If only one exists (e.g., only `.light()` because we ship light at MVP), add a `.dark()` factory that uses the dark color tokens from `colors.dart`. Per UI-PRINCIPLES.md, dark mode tokens are defined from day one even though we ship light only.

If you need to add `.dark()`, copy the structure of `.light()` and swap the `ColorScheme` to the dark token set.

## Add the run script

In `apps/mobile/package.json` (if it has scripts) or as a shell alias:

```bash
alias jbook="cd $(git rev-parse --show-toplevel)/apps/mobile && flutter run -t widgetbook/main.dart -d chrome"
```

Now `jbook` from anywhere opens the catalog.

## Visual regression — next step

Once Widgetbook is running, the Sprint 2 task "Visual regression in CI" wires it to `flutter test` with `--update-goldens`. Every Widgetbook page becomes a golden image that CI diffs on every PR.

That's a separate task — for now just confirm Widgetbook runs.

## Troubleshooting

**"Couldn't resolve the package 'jobbees'"** — the imports in `widgetbook/` use `package:jobbees/...`. Make sure `pubspec.yaml` has `name: jobbees` at the top.

**"Theme is null"** — ensure `AppTheme.light()` returns a non-null ThemeData. Common cause: the colors.dart imports are missing.

**Browser hot-reload not working** — Widgetbook's web target requires `flutter run` not `flutter build`. Confirm you're running `flutter run -t widgetbook/main.dart -d chrome`.
