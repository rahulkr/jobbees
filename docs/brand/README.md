# JOBBees brand

This directory locks the visual identity for the JOBBees product.

The palette and shape system are carried forward from the React Native prototype (located outside this repo). This provides continuity with what the client has already seen and approved.

Modern best practices (Material 3, dark mode tokens, accessibility, motion, haptics) are layered on top of the inherited palette.

## Files

| File               | What it covers                                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------------------------------- |
| `COLORS.md`        | The full color palette — primary coral orange, dark navy-charcoal, semantic colors, gradients, usage rules     |
| `UI-PRINCIPLES.md` | Modern UI principles — Material 3, typography scale, shape, motion, haptics, accessibility, dark mode strategy |

## Implementation

The brand is implemented in code at:

| Code                                   | Purpose                                                       |
| -------------------------------------- | ------------------------------------------------------------- |
| `apps/mobile/lib/theme/colors.dart`    | Flutter color tokens (light + dark schemes)                   |
| `apps/mobile/lib/theme/app_theme.dart` | Flutter `ThemeData` (Material 3, Inter font, generous shapes) |
| `apps/admin/app/globals.css`           | Tailwind v4 CSS variables matching the same palette           |
| `apps/web/app/globals.css`             | Same Tailwind tokens                                          |

These are the **single source of truth**. If a designer / dev wants to change the brand, they update these files plus the `COLORS.md` doc.

## Brand voice (for written copy)

Friendly, helpful, energetic — but trustworthy. Examples:

- ✅ "Found someone nearby — Sarah can start Saturday at 2pm"
- ❌ "Match found. Tasker available."
- ✅ "Held safely until you confirm the work is done"
- ❌ "Funds in escrow pending task completion verification"

Write like a friendly local who happens to be helpful, not like a SaaS dashboard.
