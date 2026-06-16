# Quality Bar — Inspiration

What "good" looks like for JOBBees. Use this when generating screens to calibrate the polish level.

Each row is a specific reference — not "look at the whole app" but "look at THIS interaction in this app." When you (or the AI) builds a similar screen for JOBBees, this is the bar.

---

## Mobile — overall polish

| Reference                                | Why this                                                                                 | Where it applies in JOBBees                                        |
| ---------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Cash App** — payment confirmation flow | Restrained motion, large numbers, haptic feedback, single-action focus                   | Sprint 5 — payment authorise, Sprint 6 — auto-capture confirmation |
| **Airbnb** — host onboarding             | Long multi-step flow that doesn't feel like a long multi-step flow; progress is implicit | Sprint 2 — Become a Tasker, Sprint 4 — license upload              |
| **Notion** — bottom sheets               | Sheet-first navigation; never lose the surrounding context                               | Sprint 5 — messaging attachments, Sprint 3 — AI extraction confirm |
| **Linear** — empty states                | Empty states that double as tutorials; never a sad face                                  | Sprint 11 — every empty state in the app                           |
| **Apple Maps** — directions sheet        | Snappable bottom sheet with three discrete heights; no awkward in-between states         | Sprint 4 — map view of nearby jobs                                 |
| **Stripe** — receipt PDFs                | Generous whitespace, clear hierarchy, no logo bloat                                      | Sprint 6 — tax invoice + RCTI PDFs                                 |
| **DoorDash** — order tracking            | Single big "what's happening" indicator at top; calm secondary info                      | Sprint 8 — job-in-progress screen                                  |
| **Uber** — driver acceptance             | Two big buttons, large touch targets, time pressure visible                              | Sprint 4 — accept/decline offer flow                               |
| **Calm** — first-launch                  | Welcome carousel that's three slides, skippable, never patronising                       | Sprint 2 — welcome carousel                                        |

## Mobile — specific patterns

| Pattern                   | Reference                                   | Apply to                                     |
| ------------------------- | ------------------------------------------- | -------------------------------------------- |
| Live location share       | Find My / Uber driver tracking              | Sprint 6 — tasker en route                   |
| Camera + AI extraction    | Apple Photos OCR / Google Lens              | Sprint 3 — photo-based job posting           |
| Voice input UX            | Apple Siri waveform / Krisp listening state | Sprint 3 — voice posting                     |
| OTP autofill              | iOS Smart Auth / Android SMS Retriever      | Sprint 2 — phone verification                |
| Address picker            | Uber pickup / Apple Maps drop-pin           | Sprint 3 — job location                      |
| Card add via PaymentSheet | Stripe's own iOS demo app                   | Sprint 5 — add card                          |
| Bottom sheet for confirm  | Material 3 spec / Notion                    | Sprint 5 — confirm offer accept              |
| Push notification         | iOS native — never custom in-app banners    | Sprint 8 — all notifications                 |
| Loading skeleton          | Vercel / Linear                             | Sprint 2 onwards — every list, card, profile |

## Web — overall polish

| Reference                | Why this                                   | Where it applies in JOBBees                        |
| ------------------------ | ------------------------------------------ | -------------------------------------------------- |
| **Vercel dashboard**     | Clean grid, generous whitespace, fast feel | Sprint 9 — admin console                           |
| **Linear**               | Information density done right; no clutter | Sprint 9 — admin lists                             |
| **Stripe Dashboard**     | Read-heavy without overwhelm               | Sprint 9 — payment + payout dashboards             |
| **Notion**               | Public job page polish                     | Sprint 3 — public Next.js job pages                |
| **Airbnb listing pages** | SEO-rich pages that don't feel SEO-spammy  | Sprint 11 — programmatic category × location pages |

## Web — specific patterns

| Pattern                       | Reference                           | Apply to                                                         |
| ----------------------------- | ----------------------------------- | ---------------------------------------------------------------- |
| Admin command palette (Cmd-K) | Linear / Vercel                     | Sprint 9 — admin power-user navigation (deferred to V2 if tight) |
| Public page hero              | Airbnb / Notion                     | Sprint 11 — marketing landing                                    |
| Map view (web)                | Google Maps embed but custom-styled | Sprint 4 — web parity for ranked feed                            |
| Sticky filters                | Airbnb search                       | Sprint 4 — web discovery                                         |
| Modal forms                   | Linear / Vercel                     | Sprint 9 — admin create/edit dialogs                             |

## Anti-patterns — DO NOT do these

| What to avoid                           | Why                                                                 |
| --------------------------------------- | ------------------------------------------------------------------- |
| Gradient mesh backgrounds everywhere    | We're a marketplace not a generative art studio                     |
| Glass-morphism on every card            | Was 2022; reads dated now                                           |
| Drop shadows on everything              | Material 3 uses elevation tokens — let the framework do it          |
| Custom date pickers                     | Use native iOS / Android pickers; never reinvent                    |
| In-app rating modals after every action | One per cohort, well-timed                                          |
| Coach marks on every screen             | We have contextual tooltips at 5-6 key moments only (S11)           |
| "Tap anywhere to dismiss" tutorials     | Dismiss patterns should be obvious or there shouldn't be a tutorial |
| Custom toast positioning                | Stay top-or-bottom OS-native                                        |
| Skeuomorphic anything                   | We're not Apple Notes 2010                                          |
| Spinner-only loading states             | Use skeletons; spinners only on actions < 2s                        |
| Splash screens with brand video         | Splash is 800ms max, brand-mark only                                |
| Confetti / particles on success         | Cash App does this once at signup. Not every successful action.     |
| Force-modal upsells                     | Never.                                                              |

## How to add to this list

When you find an app that does something well — anywhere in the build:

1. Add a row to the right table above
2. Note the **specific** interaction (not the whole app)
3. Note the JOBBees sprint where it applies
4. Optionally: drop a screenshot / Loom in this folder, link from the row

The point isn't to copy. The point is to give the AI (and yourself) a concrete reference so "quality" isn't subjective.

---

## When the AI is building a screen

Tell it (or include in CLAUDE.md update later):

> "Before building this screen, check `docs/brand/inspiration/README.md` for the closest reference. Match that polish level."

This bypasses 80% of the "looks generic" problem.
