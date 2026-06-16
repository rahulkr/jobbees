# JOBBees UI — thin Material 3 layer

Our component library. Sits on top of Material 3 widgets, adds brand tokens, enforces the patterns in `docs/brand/UI-PRINCIPLES.md` and the copy rules in `docs/brand/VOICE.md`.

**Zero library dependencies.** We don't use shadcn-style component kits because they couple us to someone else's release cadence and design choices. Instead we compose Material 3 + our brand tokens + our voice.

## Why a thin layer?

Three reasons:

1. **Consistency** — every button looks like every other button. Every dialog feels like every other dialog. The AI reaches for `JPrimaryButton` and doesn't reinvent a custom `RaisedButton` with a slightly different padding.
2. **Constraints over choices** — the AI generates better UI when there are fewer ways to do something. Our `JButton` has 4 variants (primary/secondary/danger/ghost) and 3 sizes (sm/md/lg) — that's it.
3. **One place to change** — when we decide to soften corners or tweak the focus ring, we change one file and every screen updates.

## Layout

```
apps/mobile/lib/ui/
├── README.md (this file)
├── tokens/
│   ├── colors.dart         — re-exports from theme/colors.dart (single source)
│   ├── spacing.dart        — 4/8/12/16/24/32/48/64 scale
│   ├── radius.dart         — 12/16/24/32 (chip / button-md / card / hero)
│   ├── motion.dart         — durations + curves
│   └── elevation.dart      — Material 3 levels 0/1/2/3 only
├── components/
│   ├── buttons/
│   │   ├── j_button.dart           — primary / secondary / danger / ghost variants
│   │   ├── j_icon_button.dart      — small circular icon-only
│   │   └── j_fab.dart              — Floating Action Button (Post a Job)
│   ├── inputs/
│   │   ├── j_text_field.dart       — single-line with label + helper + error
│   │   ├── j_text_area.dart        — multi-line
│   │   ├── j_otp_field.dart        — 6-digit OTP
│   │   └── j_search_field.dart     — with leading magnifier
│   ├── containers/
│   │   ├── j_card.dart             — flat or elevated, with brand corner radius
│   │   ├── j_bottom_sheet.dart     — 3-snap (peek/half/full), spring physics
│   │   └── j_modal.dart            — only for confirmations; never for navigation
│   ├── feedback/
│   │   ├── j_snackbar.dart         — bottom, 4s default
│   │   ├── j_empty_state.dart      — illustration + title + body + CTA
│   │   ├── j_error_state.dart      — state-the-problem-state-the-fix
│   │   └── j_loading_skeleton.dart — shimmer-based skeleton (never spinners)
│   ├── data/
│   │   ├── j_list_tile.dart        — semantic list rows
│   │   ├── j_avatar.dart           — user avatar with initial fallback
│   │   ├── j_chip.dart             — tags, filters, status badges
│   │   └── j_badge.dart            — count notification badge
│   └── navigation/
│       ├── j_app_bar.dart          — standard top bar with back arrow
│       ├── j_bottom_nav.dart       — 5-slot bottom navigation
│       └── j_tab_bar.dart          — segmented control on top of a screen
└── platform/
    ├── j_haptics.dart              — wrapped HapticFeedback per VOICE.md table
    └── j_dialogs.dart              — conversational confirm via JModal
```

## The rules

1. **Every component name starts with `J`** — `JButton`, `JCard`, `JBottomSheet`. Makes it grep-friendly and signals "this is our component, not a Material default."

2. **Components only consume tokens.** Never hardcode a color, size, or duration inside a component. If you need a value that's not in tokens, add it to tokens first.

3. **One way to do each thing.** If there are two ways to render a primary button (`JButton.primary()` AND `JPrimaryButton`), pick one. We use named constructors: `JButton.primary()`, `JButton.secondary()`.

4. **Every component documents its states.** Loading, empty, error, content, disabled. If a component doesn't have a loading state, document why.

5. **No business logic in components.** A `JButton` knows about visual states. It doesn't know about offers or payments. Logic lives in Riverpod providers or controllers.

6. **Every component lands in Widgetbook with all states visible.** No exceptions. If a component isn't in Widgetbook, the AI can't see it.

7. **Voice + microcopy follow `docs/brand/VOICE.md`.** When you pass a label to `JButton`, it should follow the forbidden-phrase list.

## What this layer is NOT

- **Not a design system in the formal sense.** No Figma source-of-truth, no design tokens JSON, no Style Dictionary. We're a small team — over-engineering kills us.
- **Not a replacement for Material 3.** When a screen needs a Material widget we don't wrap, just use the Material widget. We wrap the high-traffic ones.
- **Not generic.** It's specifically tuned for JOBBees — AU marketplace, mobile-first, warmth + plain-speaking.

## Adding a component

1. Decide if it really needs a `J*` wrapper. If you're using Material's widget exactly as-is with default styling — no wrapper needed.
2. If yes, create `apps/mobile/lib/ui/components/<category>/j_<name>.dart`.
3. Use ONLY tokens for visual values.
4. Add a Widgetbook page in `apps/mobile/widgetbook/components/<category>/j_<name>_page.dart`.
5. Document every state.

## Theme wiring

`apps/mobile/lib/theme/app_theme.dart` is the entry point. It builds `ThemeData` from the tokens above and feeds Material 3's `colorScheme`. Components consume `Theme.of(context)` not the tokens directly — this is what lets dark mode work for free later.

## When the AI generates a new screen

It should:

1. Check `docs/brand/inspiration/README.md` for the closest reference
2. Use `JButton`, `JCard`, etc. — never raw Material widgets where a wrapper exists
3. Apply `docs/brand/VOICE.md` for every string
4. Add the screen's components (if any) to Widgetbook before merging

When it doesn't, flag in PR review.
