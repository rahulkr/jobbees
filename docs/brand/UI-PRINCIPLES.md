# UI principles — modern best practice

Modern best-of-industry patterns layered on top of the brand palette in `COLORS.md`. The colors are inherited from the previous prototype; the principles below bring the UI up to 2026 standard.

## Design system

**Material 3 (Material You)** via Flutter 3.44+. We use `useMaterial3: true` everywhere. This gives us:

- Dynamic shape (rounded corners scale with surface)
- Filled / Outlined / Text button variants with semantic distinction
- ColorScheme.fromSeed() for tonal palettes (we override with explicit JOBBees shades, but the scaffolding is M3-native)
- Modern elevation tokens (1-5 levels)
- Built-in accessibility primitives

We do NOT use Material 2 widgets. We do NOT use Cupertino-style on iOS — we keep one design system across platforms for consistency.

## Typography

Inter font family (already chosen in the prototype). Material 3 type scale, with JOBBees-specific weight choices:

| Token (M3 name)  | Size | Weight         | Use                                 |
| ---------------- | ---- | -------------- | ----------------------------------- |
| `displayLarge`   | 32px | 700 (Bold)     | Splash, hero moments only           |
| `headlineLarge`  | 28px | 700 (Bold)     | Onboarding screen titles            |
| `headlineMedium` | 24px | 700 (Bold)     | Screen titles, "Welcome back"       |
| `titleLarge`     | 18px | 600 (SemiBold) | Card titles, list section heads     |
| `titleMedium`    | 16px | 600 (SemiBold) | Button labels, in-card titles       |
| `bodyLarge`      | 16px | 400 (Regular)  | Default body                        |
| `bodyMedium`     | 14px | 400 (Regular)  | Secondary body                      |
| `bodySmall`      | 12px | 400 (Regular)  | Captions                            |
| `labelLarge`     | 14px | 600 (SemiBold) | Form labels                         |
| `labelSmall`     | 11px | 500 (Medium)   | Tiny labels (chip text, badge text) |

**Line height**: 1.4-1.6 for body, 1.2 for headlines. **Letter spacing**: 0 (default) — Inter handles this well.

Use `google_fonts: ^6.x` Flutter package to load Inter at runtime (lighter app bundle than bundling the font file).

## Spacing — 8pt grid

All spacing is a multiple of 4 (preferably 8). No magic numbers like 7 or 13.

| Token  | Value | Use                                                |
| ------ | ----- | -------------------------------------------------- |
| `xs`   | 4     | Icon padding, tight chip gap                       |
| `sm`   | 8     | Item gap in a list                                 |
| `md`   | 12    | Form field inner padding                           |
| `base` | 16    | Default screen padding, card padding               |
| `lg`   | 24    | Section spacing, card gap                          |
| `xl`   | 32    | Hero spacing, top padding                          |
| `2xl`  | 48    | Very generous, e.g. between sections in onboarding |
| `3xl`  | 64    | Splash centering                                   |

## Shape

Inherited from the prototype, generous corners:

| Token       | Radius | Use                                   |
| ----------- | ------ | ------------------------------------- |
| `chip`      | 12     | Small chips, tags                     |
| `button-md` | 16     | Default button                        |
| `button-lg` | 24     | Hero button                           |
| `card`      | 24     | Cards, modals                         |
| `hero`      | 32     | Hero icon containers, avatars (large) |

These map to Material 3 shape tokens (small / medium / large / extra-large) in `app_theme.dart`.

## Elevation — Material 3 tokens

Material 3 uses 6 elevation levels (0-5). For JOBBees we use only 3:

| Level | dp  | Use                                                            |
| ----- | --- | -------------------------------------------------------------- |
| `0`   | 0   | Flat — most screens, cards default                             |
| `1`   | 1   | Subtle lift on cards (light mode), or use 1px border instead   |
| `2`   | 3   | Modals, bottom sheets, snackbars                               |
| `3`   | 6   | FAB (Floating Action Button) — used sparingly for "Post a job" |

Avoid heavy shadows. Use `dark-100` 1px borders on cards in light mode instead of elevation when possible — looks cleaner.

**One intentional exception — the primary CTA.** `JButton.primary` carries a soft, _brand-tinted_ warm lift (not a grey drop shadow) so the main action floats off the page. Kept deliberately tight — ≈18px blur, −8 spread, ~20% terracotta (`0x33D4541F`) plus a faint neutral ambient — so it reads as a _lift_, not a glowing halo (a wider/stronger blur reads as a neon halo). Source of truth: `_kCtaShadow` in `apps/mobile/lib/ui/components/buttons/j_button.dart`.

## Motion

Three principles:

### 1. Quick + subtle

- Page transitions: 250ms ease-out
- Button press feedback: 100ms spring — scale to 0.97 then settle (`JMotion.spring`, `Cubic(0.16, 1, 0.3, 1)`), via the shared `JPressable`; not a linear/ease-out fade
- Bottom sheet appear: 300ms cubic-bezier(0.16, 1, 0.3, 1) (smooth, slightly bouncy)
- Snackbar: 200ms

### 2. Respect reduced motion

```dart
if (MediaQuery.of(context).disableAnimations) {
  // skip the animation, render the destination state immediately
}
```

Test with: iOS Settings → Accessibility → Motion → Reduce Motion.

### 3. Skeleton loaders instead of spinners

For lists / feeds, show a skeleton (gray rectangles in the shape of the content) for the first 500ms. If still loading after 500ms, show the spinner. Avoids the "white screen flash" feeling.

Use `shimmer: ^3.x` Flutter package.

## Haptics

Subtle haptic feedback at key moments. Use `HapticFeedback` (built into Flutter):

| Moment                                   | Haptic                                                  |
| ---------------------------------------- | ------------------------------------------------------- |
| Offer placed                             | `HapticFeedback.lightImpact()`                          |
| Offer accepted (client)                  | `HapticFeedback.mediumImpact()`                         |
| Payment authorised                       | `HapticFeedback.mediumImpact()`                         |
| Job completed                            | `HapticFeedback.heavyImpact()` (the celebration moment) |
| Error / validation failure               | `HapticFeedback.vibrate()` (the longer feedback)        |
| Navigation tap (chip select, tab switch) | `HapticFeedback.selectionClick()`                       |

Respect the system setting to disable haptics (iOS Settings → Sounds & Haptics).

## Accessibility — WCAG 2.1 AA

Inventory row 218 commits us to WCAG 2.1 AA basics. Concrete requirements:

- All interactive elements have `Semantics(label: ...)` for screen readers
- Minimum tap target 44x44 (iOS) / 48x48 (Android)
- All form inputs have visible labels (not just placeholders)
- Color is never the only signal — pair with icon or text
- Contrast ratios pass (see `COLORS.md` contrast table)
- Dynamic Type / font scaling supported (use `Text.scaler` or `MediaQuery.textScaler` aware widgets)
- Tab order is logical when using keyboards (Android with external keyboard, iPadOS)
- Live regions announce changes ("Your offer was accepted")

Test with: iOS VoiceOver, Android TalkBack, system font size set to largest.

## Dark mode — define tokens, ship light only at MVP

We ship **light only** at MVP per inventory row 188 ("Theme — light only at MVP, theme-ready architecture"). But the architecture defines dark tokens from day one.

| Surface           | Light     | Dark                                        |
| ----------------- | --------- | ------------------------------------------- |
| Screen background | `#FFFFFF` | `#0F0F1D`                                   |
| Card background   | `#FFFFFF` | `#1A1A2E`                                   |
| Input background  | `#F5F5F7` | `#262640`                                   |
| Body text         | `#33334A` | `#E8E8ED`                                   |
| Headline text     | `#1A1A2E` | `#FFFFFF`                                   |
| Border            | `#E8E8ED` | `#33334A`                                   |
| Primary           | `#ED713E` | `#F4A06A` (slightly lighter for AA on dark) |
| Success           | `#22C55E` | `#4ADE80` (slightly lighter)                |

To enable dark mode later: flip `themeMode: ThemeMode.system` (or user preference) in `app_theme.dart`. No widget rewrites needed.

## Loading states

| Pattern                | When                                                                        |
| ---------------------- | --------------------------------------------------------------------------- |
| **Skeleton loader**    | List / feed content, profile pages                                          |
| **Pull-to-refresh**    | List / feed screens (with brand-colored spinner)                            |
| **Inline spinner**     | Form submission, button loading state                                       |
| **Full-screen loader** | First-time data fetch (rare — use skeleton instead)                         |
| **Optimistic UI**      | Like / save / bookmark — instantly toggle UI, reconcile on backend response |

## Empty states (per Sprint 11 row 213 expanded scope)

Every empty state has:

1. A simple illustration (use heroicons / lucide-flutter — no custom illustrations at MVP)
2. A title (e.g., "No jobs yet")
3. A one-line description (e.g., "Tap + to post your first job — the AI does the rest")
4. A primary CTA (the action they should take next)

## Snackbars + toasts

Use Material 3 `SnackBar` with:

- Position: bottom, above bottom nav
- Duration: 4s default, 8s for actions with undo
- Color: `dark-800` background, white text
- Action: optional, `primary-300` text
- Auto-dismiss on screen change

No fancy toasts. Native snackbar is fine and respects accessibility.

## Forms

- Inputs are 56px tall, 16px horizontal padding
- Background `dark-50` (`#F5F5F7`)
- Border: 2px transparent → 2px `primary` on focus
- Icon on left (16-20px), color `dark-400` → `primary` on focus
- Labels above the input (not floating)
- Error message below the input in `error` color
- Helper text below the input in `dark-400` color (less prominent than error)

## Bottom navigation (mobile)

- Material 3 NavigationBar
- 5 items max — Home / Offers / Post Job (raised center FAB) / Messages / Profile
- Active item: `primary` color icon + label
- Inactive: `dark-400` icon + `dark-600` label
- Background: white, with subtle 1px top border (`dark-100`)

## What we DON'T do

- ❌ Gradients on body text — only icons and hero elements
- ❌ Heavy shadows everywhere — use borders or M3 elevation tokens
- ❌ Custom fonts beyond Inter — too much app bundle weight
- ❌ Custom illustrations for every empty state — use lucide-flutter icons + brand color
- ❌ Animated splash > 2 seconds — wastes user time
- ❌ Modal dialogs for confirmation when bottom sheets work
- ❌ Tab bar on top of screen when bottom nav exists
- ❌ "Coach marks" that block the screen — use contextual tooltips (Sprint 11) instead

## Implementation in Sprint 1

The first PR of Sprint 1 (`feat(mobile): theme + brand setup`) will create:

```
apps/mobile/lib/theme/
  colors.dart           — JOBBees color constants + ColorScheme.light + ColorScheme.dark
  typography.dart       — Inter TextTheme using google_fonts
  app_theme.dart        — ThemeData with all of the above wired up
  shape.dart            — RoundedRectangleBorder tokens
  motion.dart           — Duration + Curve tokens
```

Plus `pubspec.yaml` additions: `google_fonts`, `shimmer`, `lucide_icons_flutter` (or `lucide_flutter`).

## 2026 patterns to bake in

Above and beyond Material 3 defaults, these are the specific patterns that lift the app from "2022 generic" to "2026 modern." When the AI builds a screen, it should default to these.

### Bottom-sheet-first navigation

When a flow can fit in a bottom sheet, prefer that over a new screen. Sheet-first means:

- The user never loses the surrounding context (their feed, their thread, their map)
- Three discrete heights (`peek`, `half`, `full`) — never an awkward in-between state
- Snap to the nearest height on drag release; never let the sheet float at 47%
- Tap outside or drag-down to dismiss
- For multi-step flows inside the sheet, push within the sheet (not over the top)

Reference: Apple Maps directions sheet (perfect 3-snap behaviour).

Applies to: AI extraction confirm (S3), offer placement (S4), payment confirm (S5), reviews submission (S7), all settings sub-flows.

### Optimistic UI by default

For any action where success is the overwhelmingly likely outcome (95%+), update the UI instantly and reconcile on backend response:

| Action                  | Optimistic update                             | Reconcile if                                              |
| ----------------------- | --------------------------------------------- | --------------------------------------------------------- |
| Send message            | Add to thread immediately, grey out until ACK | Server returns 4xx → toast "Couldn't send" + retry button |
| Like / save / favourite | Toggle icon state instantly                   | Server fails → revert + toast                             |
| Mark notification read  | Hide badge instantly                          | (no reconcile needed — server eventually consistent)      |
| Withdraw offer          | Remove from list instantly                    | Server returns 4xx → restore + toast                      |

Never: payment actions (never optimistic — too high stakes), offer accept (server-of-record), license upload (sensitive).

### Skeleton everywhere, spinners almost never

Default loading state is a skeleton in the exact shape of the content that's coming. Use spinners only when:

1. The action is < 1 second (button press while saving)
2. There's no predictable shape (e.g., AI response streaming)
3. The user has explicitly triggered something (pull-to-refresh)

Every list, every grid, every profile page has a skeleton state. Use `shimmer` package as already specced above.

### Haptics as language

Different actions get different haptic patterns. The pattern becomes part of the action's signature — users learn it.

(Already covered in the Haptics table above. Reiterating: be disciplined. Don't fire haptics on every tap or it loses meaning.)

### Spring physics, never linear

For any non-trivial transition (bottom sheet, modal, drag-to-dismiss, list reorder), use spring physics. Flutter's `SpringSimulation` or `flutter_animate` package, or the M3 motion tokens.

Linear ease feels mechanical. Spring feels responsive.

### Conversational confirmations

Confirm modals never show "OK" or "Cancel." Always restate the action in the affirmative button.

| Bad                            | Good                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------- |
| Are you sure? [OK] [Cancel]    | Withdraw your offer? [Yes, withdraw] [Keep it open]                             |
| Confirm payment? [OK] [Cancel] | Pay $84 now? [Yes, pay $84] [Not yet]                                           |
| Delete account? [OK] [Cancel]  | Delete your account? This can't be reversed. [Yes, delete it] [Keep my account] |

(Covered in `VOICE.md` too — reiterating because it's the single most common AI miss.)

### Reduced motion respect

If the user has reduced motion enabled at the OS level:

- Skip page transition animations (cut to destination)
- Skip skeleton shimmer (show static skeleton, then content)
- Skip spring physics (snap to destination state)
- Keep haptic feedback (different accessibility need)
- Keep loading spinners (informational, not decorative)

Test: iOS Settings → Accessibility → Motion → Reduce Motion → ON.

### Adaptive density

Compact phones (< 380dp width) and tablets (> 600dp width) need different density:

- Compact: tighter padding, smaller touch targets at the minimum (44px), single-column layouts
- Regular: defaults (per the spacing scale above)
- Wide: 2-column for lists, side-by-side detail panes, larger images

Use `LayoutBuilder` + `MediaQuery.of(context).size.width` breakpoints. Don't hardcode — drive from the spacing scale.

### Dark mode parity from day one

We ship light at MVP but every component should be dark-mode-ready. When you build a screen:

1. Use `Theme.of(context).colorScheme.*` not hardcoded colors
2. Test in both modes via dev menu (we'll add a hidden toggle in Widgetbook)
3. If something doesn't read in dark mode, that's a real bug, not a "we'll fix later"

Flipping the production switch later becomes a 1-line change in `app_theme.dart`.

### Native components for natively-good things

When the OS provides a thing, use the OS thing:

- Date picker: native iOS / Android pickers (use `showDatePicker()` which adapts per platform)
- Photo picker: native (file picker / gallery / camera)
- Share sheet: native (`share_plus` package wraps both)
- Notifications: native (no in-app banner replacements)
- Authentication prompts (Touch ID / Face ID): `local_auth` package

Never reinvent these. The native experience is what users expect.

### Anti-patterns specifically for 2026

These were fashionable but read as dated:

- ❌ Glass-morphism on every card (was 2022; reads cheap now)
- ❌ Gradient mesh backgrounds (overused; reserved for hero / paywall moments only)
- ❌ Custom in-app web views for OAuth (use system browser — security AND polish)
- ❌ Skeuomorphic anything (we're not Notes 2010)
- ❌ Confetti / particle effects on every success (Cash App does this once at signup — that's the bar)
- ❌ "Coach mark" tutorials that block the screen (contextual tooltips at 5-6 moments only — already in S11)
- ❌ Modal upsells for trial / paid features (we're a marketplace; this isn't our problem at MVP)
- ❌ Force-modal "Rate the app" prompts (one per cohort, well-timed)
- ❌ Custom toast positioning (top-or-bottom OS-native; consistent)

## References

- Material 3 design: https://m3.material.io/
- Flutter Material 3 migration: https://docs.flutter.dev/release/breaking-changes/material-3-migration
- WCAG 2.1 AA quick reference: https://www.w3.org/WAI/WCAG21/quickref/
- Apple HIG (for iOS-specific patterns we adapt): https://developer.apple.com/design/human-interface-guidelines
- Inspiration references: [`docs/brand/inspiration/README.md`](./inspiration/README.md)
- Voice + microcopy guide: [`docs/brand/VOICE.md`](./VOICE.md)
