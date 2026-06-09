# CLAUDE.md — apps/mobile (Flutter)

User-facing app for both posters and taskers. Calls the NestJS API for everything — no business logic in Flutter.

## Stack

- Flutter 3.24+ on Dart 3.5+ (iOS + Android)
- Riverpod (state management with code generation)
- go_router (declarative routing)
- dio (HTTP client with interceptors)
- freezed + json_serializable (immutable models)
- flutter_secure_storage (token storage)
- local_auth (Face ID / Touch ID / fingerprint)
- Stripe Flutter SDK (payment UI)
- firebase_messaging (push notifications)
- google_maps_flutter or mapbox_gl (map view)

## Folder structure

```
apps/mobile/lib/
├── main.dart
├── app.dart                          # root MaterialApp + theme + router
├── core/                             # cross-cutting
│   ├── theme/                        # ColorScheme tokens, typography, theme-ready
│   ├── network/                      # dio setup, auth interceptor, error mapper
│   ├── storage/                      # secure storage wrapper
│   ├── router/                       # go_router config, auth guard
│   ├── analytics/                    # PostHog/Mixpanel wrapper
│   └── error/                        # error reporting (Sentry)
├── features/                         # feature-first folders
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/                # Riverpod providers
│   │   ├── models/
│   │   └── repositories/             # API client wrapper
│   ├── profile_poster/
│   ├── profile_tasker/
│   ├── task_posting/
│   ├── task_discovery/
│   ├── bidding/
│   ├── job_execution/
│   ├── messaging/
│   ├── payments/
│   ├── cancellation/
│   ├── reviews/
│   ├── disputes/
│   ├── notifications/
│   ├── settings/
│   └── support/
└── shared/                           # reusable widgets
    ├── widgets/
    └── extensions/
```

## Hard rules — never violate

1. **Never hardcode colours.** Always use `Theme.of(context).colorScheme.x` or named tokens from `core/theme`. Light only at MVP; theme tokens are scaffolded so dark mode is one swap later.
2. **Never call dio directly from screens.** Use a repository class (`features/<name>/repositories/<name>_repository.dart`) that wraps the API call.
3. **Every screen has four states.** Loading, error, empty, content. Use a `AsyncValue`-aware widget pattern.
4. **Riverpod for ALL state.** No `StatefulWidget` for app-level state. Local `useState` (via flutter_hooks) only for screen-local UI state (toggle, text controller).
5. **Auth state changes drive navigation.** Subscribe to `authStateProvider` in the router redirect; never push routes from a button on a login screen.
6. **Stripe payments via official Stripe Flutter SDK.** Never roll custom card input. Apple Pay / Google Pay through Stripe's PaymentSheet.
7. **Soft delete is server-side.** Never call delete endpoints expecting hard delete on user-facing entities.
8. **Network errors render as the error state.** Never silently swallow. Use the `ErrorMapper` to convert dio errors to user messages.
9. **Always set `autofillHints: [AutofillHints.oneTimeCode]`** on OTP fields. iOS Smart Auth + Android SMS Retriever depend on it.
10. **App lifecycle handlers** for background tasks (location during active job). Pause on `AppLifecycleState.paused`, resume on `resumed`.

## Conventions

- **Naming:** `snake_case` for files, `PascalCase` for classes, `camelCase` for variables.
- **Imports:** package imports above relative imports, alphabetised.
- **Models:** generated via `freezed` + `json_serializable`. Run `dart run build_runner build --delete-conflicting-outputs` after model edits.
- **Riverpod:** use `@riverpod` code-gen syntax, not the legacy provider syntax. Run build_runner after provider edits.
- **Strings:** all user-facing strings in `lib/l10n/app_en.arb` (even though we're English-only at MVP — scaffolds i18n cheaply).
- **Form validation:** use `reactive_forms` package or manual `TextEditingController` + validator functions in providers.

## Theme-ready architecture

Don't ship dark mode at MVP, but make adding it later a config change:

- Define semantic colour tokens in `core/theme/color_tokens.dart` (`primary`, `surface`, `onSurface`, `danger`, etc.)
- Build light theme from these tokens
- All widgets use `Theme.of(context).colorScheme` — never raw `Color(0xFF...)`
- Adding dark mode = define dark token set + add theme switcher

## Testing

- Widget tests for screens: `test/features/<name>/<screen>_test.dart`
- Use `riverpod_test` for provider unit tests
- Mock API responses via dio's `MockAdapter`
- Run with `flutter test`
- Integration tests in `integration_test/` (separate from widget tests)

## Run

- `cd apps/mobile`
- `flutter pub get`
- `flutter run` (with a device or emulator connected)
- `flutter test` (unit + widget tests)
- `flutter analyze` (static analysis, fail on warnings)

## What's NOT here

- Apple Developer + Google Play accounts (client-owned)
- App icons, splash assets (client-supplied)
- Branding (client-supplied)
- Backend code (lives in `apps/api`)
