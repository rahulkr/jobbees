# Social sign-in — device setup & verification

Google and Apple sign-in are wired in code (`features/auth/data/social_auth_service.dart`)
behind the `SocialAuthService` interface. The Dart logic, repository, controller,
and UI are unit-tested, but the native provider flows **cannot be exercised in CI /
headless** — they need a real simulator/device. This is the checklist to verify and
finish the platform wiring.

## Backend (already done)
- `GOOGLE_OAUTH_CLIENT_IDS` (iOS + Web) and `APPLE_CLIENT_IDS` (`com.seaford.jobbees`)
  are set in the API's `.env.local`. The API verifies the ID token's `aud` against
  these. No client secret is needed (ID-token verification only).

## iOS — Google (done in code, verify on device)
- `ios/Runner/Info.plist` now has `GIDClientID` (iOS client) + the reversed-client-ID
  URL scheme. Nothing else needed. Verify: tap "Continue with Google" on a simulator
  → Google sheet → returns to app signed in.

## iOS — Apple (needs one Xcode step)
- `ios/Runner/Runner.entitlements` declares `com.apple.developer.applesignin`.
- **Manual step:** in Xcode, select the Runner target → Signing & Capabilities →
  set the entitlements file (or add the "Sign in with Apple" capability, which links
  it). Confirm the build setting `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`
  is present for Debug + Release. (Hand-editing `project.pbxproj` is avoided here on
  purpose — do it through Xcode so the project file stays valid.)
- Requires the paid Apple Developer Program + the App ID's "Sign in with Apple"
  capability (already registered).

## Android — Google (needs an OAuth client)
- Android Google sign-in needs an **Android OAuth client** in Google Cloud, keyed by
  the app's signing-cert SHA-1. With Play App Signing, take the SHA-1 from Play Console
  → Setup → App integrity, create the Android client, and (for local debug) also add
  the debug keystore SHA-1.
- The code already passes the **web client ID** as `serverClientId`, so the returned
  ID token's audience is the web client (already in the allow-list). No code change;
  this is purely the Cloud Console + SHA-1 step. Until done, Google sign-in will fail
  on Android only.
- Apple sign-in on Android is intentionally **not offered** (no native flow); the
  button is hidden on non-Apple, non-web platforms.

## Web (later)
- Google web uses the web client ID (already wired). Apple web needs the Services ID
  + verified domain (deferred until the web app has a hosting domain).

## Quick manual test matrix
| Platform | Google | Apple |
| --- | --- | --- |
| iOS simulator | tap → sheet → home | tap → Face ID → home (after Xcode capability) |
| Android emulator | needs Android OAuth client first | n/a (hidden) |
| Chrome (web) | web client | deferred (Services ID) |
