# Design Quality Charter

**Read this before designing or implementing any Flutter screen. This is mandatory reading for every mobile session.**

---

## The mandate

> **You are an award-winning Flutter UI designer.**
> **Do not create generic Flutter screens.**
> **Design every screen like a premium production application.**

If a screen you're about to write, review, or approve would blend in with any other Material 3 starter template, **stop and redesign.** The bar is not "shippable." The bar is "screenshottable" — a user could screenshot any screen in this app and it would be recognisably JOBBees, not recognisably Flutter.

This charter is the rejection filter. `UI-PRINCIPLES.md` tells you _what tokens to use_; this charter tells you _when to reject your own work and start over_.

---

## The 12 rejection criteria — reject and redesign if ANY apply

A screen is not ready to merge if:

1. **It looks like Material 3 defaults with a coral tint.** Default `AppBar`, default `Scaffold` background, default `ListTile`, default `ElevatedButton` — none of these ship. Every surface goes through the `J*` component library or a composed layout that clearly wasn't dragged from a template.

2. **The coral appears more than twice on one screen.** One dominant CTA + at most one accent moment (a chip, a link). Everything else is neutral. If you count 3+ coral hits, remove until there are 2. Nothing draws the eye when everything is coral.

3. **The main content is a wall of same-shaped white rectangles.** Featured, urgent, sponsored, accepted, pending — these must be _visually distinct_, not just labelled. Tinted borders, subtle background wash, top-left status ribbon — pick one system per screen and commit.

4. **There is no motion.** Every screen has an entrance (list items stagger in, hero fades up, sheet springs), and every interactive element has a press response. Static-on-load is a rejection.

5. **There is no skeleton state.** Spinners are banned in list, feed, profile, and detail screens. If the content shape is predictable, the loading state is a shimmer in that shape. Spinner-first is a rejection.

6. **There is no designed empty state.** "No results" as plain text is a rejection. Every empty state has: a Lucide icon (never Material Icons at large sizes), a title in the microcopy voice, a one-line body, and either a primary CTA or a clear reason it's empty.

7. **There is no designed error state.** Red text alone is a rejection. Error states get their own layout: an icon, a title that names the problem in plain English, a one-line body, a "Try again" button, and (where useful) an alternative action.

8. **Long text overflows or breaks the layout.** Copy-paste a 40-character job title into every text field. If it overflows the container, ellipsises awkwardly, or pushes buttons off screen, redesign.

9. **The keyboard-up state was not considered.** On any screen with input, open the keyboard mentally. Does the primary CTA disappear behind it? Does the input scroll into view? Is the tab bar covered? If any of those, redesign the keyboard layout.

10. **The screen looks identical in light and dark mode.** A palette swap is not dark-mode design. Dark mode should feel _intentionally darker_ — surface tones step up (elevation via lightness), coral tones warmer, borders more visible. Test both. If they feel like the same design in two colours, redesign the dark version.

11. **The brand mark appears anywhere it isn't a brand moment.** No app icon in the app bar of content screens. No logo decoration on cards. The mark belongs on splash, onboarding, login, and empty-brand-slate moments — not everywhere.

12. **The screen has no personality of its own within the app.** Onboarding, feed, chat, payment, profile, settings — these are _different app moods_, not variants of one template. If your payment screen has the same compositional rhythm as your settings screen, one of them is generic.

---

## The screen-specific personality bar

Each screen category has a compositional identity. Match or exceed the named reference. The reference is the _minimum bar_, not the aspirational one.

| Screen category                 | Reference bar                                 | What "premium" looks like here                                                                                                                  |
| ------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Splash + brand entrance**     | Cash App splash, Linear splash                | Confident brand-mark entrance (scale-in + fade, or draw-on), single haptic tap on completion, considered backdrop (light or dark), no UI chrome |
| **Onboarding carousel**         | Notion mobile onboarding, Linear onboarding   | Full-bleed hero image or illustration, one sentence, generous whitespace, page indicator that isn't a row of dots                               |
| **Auth (login / signup)**       | Stripe login, Uber login, Airbnb login        | Wordmark centered, one input field visible at a time, keyboard drives the layout, social buttons secondary not primary                          |
| **OTP entry**                   | Cash App OTP, WhatsApp OTP                    | 6 boxes with auto-advance, haptic on each digit, auto-submit on 6th digit, resend timer with visible countdown                                  |
| **Role select / persona pick**  | Notion workspace picker                       | Two large tap targets with illustration + one-line description, not a segmented control                                                         |
| **Home feed (client)**          | Airbnb home, Uber Eats home                   | Quiet header, one hero moment max, listings dominate, featured vs regular visually distinct                                                     |
| **Job discovery (tasker)**      | Uber driver "trips near you", DoorDash Dasher | Map-first if location is the primary axis, list-first if ranking is the primary axis, sort/filter visible not hidden                            |
| **Job detail**                  | Airbnb listing detail                         | Photo/hero at top, price and CTA sticky at bottom, sections divided by generous whitespace not lines                                            |
| **Offer placement**             | Cash App "send" flow                          | Bottom sheet, amount input as the hero, quick presets ($20/$50/$100), primary action restates ("Offer $80")                                     |
| **Chat / messaging**            | iMessage, Signal, Slack DM                    | Bubbles tinted by sender, timestamps grouped not per-message, quick reactions, typing indicator that breathes                                   |
| **Payment authorise / confirm** | Apple Pay sheet, Stripe Checkout              | Bottom sheet, amount as hero display type, payment method as one row, single primary CTA that names the action                                  |
| **Payment success**             | Cash App success, Apple Pay tick              | Full-screen success moment, animated checkmark or coin, haptic celebration, quiet dismiss                                                       |
| **Profile (own)**               | Cash App profile, Notion profile              | Avatar + name as hero, rating/badges as secondary, actions grouped as full-bleed tap rows                                                       |
| **Profile (other user)**        | Airbnb host profile                           | Verified badges prominent, reviews as scrollable carousel, "Contact" as sticky bottom CTA                                                       |
| **Reviews submission**          | Uber post-ride, Airbnb post-stay              | Stars as hero, chips for quick tags, optional text field, "Submit" enables when minimum met                                                     |
| **Settings**                    | Apple Settings, Notion settings               | Grouped rows with icon + label + chevron, section headers in muted uppercase, no card wrappers around groups                                    |
| **Notifications inbox**         | Slack activity, Linear notifications          | Grouped by day, unread visually distinct (dot + background wash), swipe to dismiss                                                              |
| **Empty states**                | Notion empty pages, Superhuman empty inbox    | Feels like a moment, not a placeholder — the copy is warm, the illustration/icon is oversized, the CTA is optional                              |
| **Error / offline**             | Vercel error pages, Linear offline            | Named problem in plain English, "Try again" prominent, alternative action, never a red-only screen                                              |
| **Loading**                     | Cash App breathing $, Linear skeleton         | Skeleton in the exact shape of the content — never a spinner in a list/feed/profile context                                                     |

If a screen you build doesn't reach the _bar_ named for its category, redo it. The bar is not aspirational — it is the minimum.

---

## Per-screen design gate — must pass before merge

Every screen PR must attach a completed screen checklist. Add this to the PR description under **Design gate**:

```markdown
### Design gate

Screen category: <e.g. Home feed (client)>
Reference bar: <named reference from the table above>

- [ ] No default Material widgets used (only J\* components or composed custom layouts)
- [ ] Coral appears ≤ 2 times on screen; one dominant CTA
- [ ] Featured/regular/state variants are visually distinct (not just labelled)
- [ ] Entrance animation defined (not default page-push)
- [ ] Interactive elements have press response (haptic + scale/opacity)
- [ ] Skeleton state built (or spinner justified for this screen)
- [ ] Empty state built with Lucide icon + microcopy voice
- [ ] Error state built with named-problem title + retry
- [ ] Long-text overflow tested (40+ char titles, 300+ char bodies)
- [ ] Keyboard-up state tested (all inputs)
- [ ] Light + dark mode both feel intentional (not same design × 2 palettes)
- [ ] Widgetbook composed page exists at `widgetbook/screens/<category>/<name>.dart`
- [ ] Screenshotted in both modes, attached to PR
```

Any unchecked box requires either a **fix** or a **written justification** in the PR (one line — why this box does not apply to this screen).

**No screen merges with an unjustified missing check.** This is enforceable in review.

---

## The Widgetbook lock

Before implementing a screen in `lib/features/<name>/screens/`, build the composed screen page in `widgetbook/screens/<category>/<name>_page.dart` first. This is a hard rule.

Why: the screen page is a _design lock_. You review the composition, motion, empty state, and dark mode in the Widgetbook harness before writing routing, providers, and API integration. It prevents "I got the visuals right in isolation but the composed screen fell apart" — the most common failure mode of component-first design systems.

- Widgetbook screen page = the design contract
- `lib/features/.../screens/*.dart` = the wiring that fulfils the contract
- Both live in the same PR

If you cannot build the Widgetbook page (because the composition isn't figured out yet), you're not ready to write the screen.

---

## What "award-winning" looks like in practice

Concrete markers to internalise:

- **Whitespace leans generous.** When in doubt, add padding. Cramped screens feel cheap. Airy screens feel expensive.
- **Hierarchy is bold.** The most important number/word on the screen is at least 2 sizes larger than the second-most important thing. No timid all-16px designs.
- **One hero moment per screen, max.** The gradient, the display-type headline, the animated illustration — pick one. Two makes both weaker.
- **Motion has intent.** Every animation answers a question ("did my tap register?", "where did that come from?", "where is that going?"). Decoration animations are a rejection.
- **Real content, always.** Every screen renders with realistic AU tasker/client copy from `VOICE.md`. Lorem ipsum in a Widgetbook page is a rejection. `foo@bar.com` in a demo is a rejection. Use `aria.tasker123@example.com`, `Mount a 65" TV on the wall`, `Surry Hills · Tomorrow`.
- **Dark mode is designed, not derived.** Dark surface tones step up with elevation (light = shadow, dark = lightness). Coral warms slightly. Borders become more prominent because shadows disappear. If dark mode feels like light mode with the colours inverted, redesign.
- **Every screen has a signature detail.** One small thing that makes the screen memorable — a bespoke micro-interaction, a distinctive corner treatment, a signature transition. Cash App's rotating $. Linear's diagonal fill. Notion's stroke-slide. Ours: a signature detail per screen category we invent as we build (e.g., a tasteful brand-mark entrance on splash, a distinctive OTP-digit animation, a chosen success moment).

---

## What "generic Flutter" looks like — reject on sight

If you see any of these in a shipped screen, it's not ready:

- Default `AppBar` with default title style
- `ListView` of `Card` widgets with `ListTile` children
- `showDialog` with default `AlertDialog`
- `ElevatedButton` or `TextButton` used directly (must go through `JButton`)
- `CircularProgressIndicator` in the body of a list/feed/profile screen
- `BottomNavigationBar` instead of `NavigationBar` with custom active indicator
- Full-width `TextField` with default outline border (must go through `JTextField`)
- `SnackBar` with default styling (custom colour scheme required)
- `showModalBottomSheet` without `JBottomSheet` wrapper
- Icons that are `Icons.<name>` at ≥ 32px (large icons must be Lucide, custom SVG, or brand assets)
- User avatars using the brand coral gradient (avatar system is separate from brand system)
- Any `Color(0xFF...)` in a widget file (use `Theme.of(context).colorScheme.*` or brand tokens)
- Text using raw `TextStyle(fontSize: N)` (use `Theme.of(context).textTheme.*`)

These are automatic rejections in review.

---

## Brand mark discipline

The JOBBees app icon is the brand mark used in the product. Use it deliberately:

- **Brand-intro moments** — splash, onboarding hero, login hero, "About" screens, marketing site, email templates. This is where the icon lives.
- **Chrome positions** — favicon, notification icon, push chrome, tiny attribution where identity matters but content dominates. Sized down, presented cleanly.
- **Not everywhere else** — no app icon in the app bar of content screens, no logo decoration on cards, no watermarks. The icon is a brand moment, not a decoration.

A restrained brand-mark presence reads more confident than a mark that appears everywhere.

Reference: [`docs/brand/inspiration/README.md`](./inspiration/README.md).

---

## Retrofitting existing screens

Screens shipped before this charter existed are tracked in [`design-debt.md`](./design-debt.md). Each is tiered by retrofit urgency:

- **Tier A** — retrofit this sprint (splash, home, unlock, become-tasker, public tasker profile, phone verify, welcome carousel). These are high-visibility, first-impression, or conversion-critical.
- **Tier B** — retrofit at next touch. When any PR touches a Tier B file for any reason (bug, feature, refactor), the design gate must pass in the same PR before merge. The PR template enforces this.
- **Tier C** — post-MVP, deferred to a dedicated polish sprint. Justified in the tracker.

**The window is now.** Before soft launch, no user has seen any of these screens — retrofitting is free (zero UI churn). After soft launch, retrofitting means users notice, screenshots go stale, and every polish PR carries perception risk. This charter is the excuse to fix everything now.

Working through the debt: read one screen at a time, walk the 12 rejection criteria + 14-box design gate, log gaps in the tracker with concrete language (never "polish" — say what specifically), build the Widgetbook composed page as the design contract, then retrofit to match. See the workflow in [`design-debt.md § Per-screen retrofit workflow`](./design-debt.md#per-screen-retrofit-workflow-claude-code-one-screen-at-a-time).

## Priority order for future screens (Sprints 3-11)

For sprints yet to be built, prioritise design-first work in this order — highest ROI first:

1. **Job posting flow (Sprint 3)** — the primary user action; must feel like Cash App send flow, not a form
2. **Job detail + offer placement (Sprint 4)** — the conversion moment
3. **Payment confirm + success (Sprint 5)** — the trust moment (Apple Pay bar)
4. **Chat + messaging (Sprint 5)** — the retention moment (iMessage bar)
5. **Empty states across the app (Sprint 8, but retrofit earlier)** — cheap to fix, disproportionate polish gain
6. **Settings + profile screens (Sprints 8-9)** — easy to leave generic, worth 30 min per screen

---

## Non-negotiables — I cannot be argued out of these

- No generic Material widgets on screens (rejection #1 above)
- No coral outside the two-per-screen budget (rejection #2)
- Skeleton, not spinner, in any predictable-shape context (rejection #5)
- Widgetbook screen page exists before `lib/features/.../screens/` file (Widgetbook lock)
- Design gate checklist attached to every screen PR (screen gate)

Everything else is a judgement call. These five are not.

---

## References

- Component-level rules: [`UI-PRINCIPLES.md`](./UI-PRINCIPLES.md)
- Colour palette: [`COLORS.md`](./COLORS.md)
- Microcopy voice: [`VOICE.md`](./VOICE.md)
- Reference apps by category: [`inspiration/README.md`](./inspiration/README.md)
- Widgetbook harness: [`apps/mobile/widgetbook/main.dart`](../../apps/mobile/widgetbook/main.dart)
- PR template: [`.github/pull_request_template.md`](../../.github/pull_request_template.md)

---

_Last reviewed: 2026-07-02. Update when the design bar rises. It never falls._
