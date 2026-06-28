# Brand colors

Locked from the React Native prototype. **Do not introduce new brand colors without updating this file + the Flutter / Tailwind implementations.**

## Primary palette — honey orange (the brand color)

Re-based on the logo's actual orange (`#ED713E`) — a warmer, softer **honey** tone than the old hot coral (`#FF6B2C`, which read as a "warning"). On-brand for the honeycomb mark (bees → honey). Changed per client note #1.

| Token                         | Hex           | Use                                                            |
| ----------------------------- | ------------- | -------------------------------------------------------------- |
| `primary-50`                  | `#FDF3EC`     | Lightest backgrounds, hover surfaces, info banner background   |
| `primary-100`                 | `#FBE3D2`     | Subtle accents                                                 |
| `primary-200`                 | `#F6C5A0`     | Light borders                                                  |
| `primary-300`                 | `#F0A572`     | Light highlights                                               |
| `primary-400`                 | `#EE8B53`     | Lighter button hover                                           |
| **`primary` / `primary-500`** | **`#ED713E`** | **Main brand color — primary CTAs, focus states, links, logo** |
| `primary-600`                 | `#DB5E2C`     | Pressed/active state                                           |
| `primary-700`                 | `#B84A24`     | Deep accents — primary-on-light text                           |
| `primary-800`                 | `#92391E`     | Very dark                                                      |
| `primary-900`                 | `#76301B`     | Deepest                                                        |

## Dark palette — deep navy-charcoal (the contrast color)

| Token                   | Hex           | Use                                                        |
| ----------------------- | ------------- | ---------------------------------------------------------- |
| `dark-50`               | `#F5F5F7`     | Input backgrounds, subtle surfaces, card backgrounds (alt) |
| `dark-100`              | `#E8E8ED`     | Light dividers                                             |
| `dark-200`              | `#D1D1DB`     | Borders, outline button border                             |
| `dark-300`              | `#A3A3B5`     | Placeholder text, disabled text                            |
| `dark-400`              | `#71718A`     | Secondary text, captions, inactive icons                   |
| `dark-500`              | `#4A4A62`     | Muted text                                                 |
| `dark-600`              | `#33334A`     | Body text                                                  |
| `dark-700`              | `#262640`     | Subheadings                                                |
| **`dark` / `dark-800`** | **`#1A1A2E`** | **Main dark — headlines, secondary buttons, active icons** |
| `dark-900`              | `#0F0F1D`     | Deepest dark                                               |

## Semantic colors

| Token          | Hex       | Use                                                         |
| -------------- | --------- | ----------------------------------------------------------- |
| `success`      | `#22C55E` | "Verified" badges, success states, completion confirmations |
| `success-dark` | `#16A34A` | Success gradient end                                        |
| `warning`      | `#F59E0B` | Held funds banner, pending states                           |
| `error`        | `#EF4444` | Validation errors, destructive actions                      |
| `info`         | `#3B82F6` | Information banners                                         |

## Background + surface tokens

| Token            | Hex       | Use                                                    |
| ---------------- | --------- | ------------------------------------------------------ |
| `bg-screen`      | `#FFFFFF` | Main screen background (light mode)                    |
| `bg-screen-dark` | `#0F0F1D` | Main screen background (dark mode — equals `dark-900`) |
| `bg-card`        | `#FFFFFF` | Card backgrounds (light mode)                          |
| `bg-card-dark`   | `#1A1A2E` | Card backgrounds (dark mode — equals `dark-800`)       |
| `bg-input`       | `#F5F5F7` | Input field background (light mode — equals `dark-50`) |
| `bg-input-dark`  | `#262640` | Input field background (dark mode — equals `dark-700`) |

## Gradients

For hero elements, icon containers, and celebration moments. **Always use a 135deg diagonal (top-left → bottom-right).**

| Token                     | Definition                                          | Use                                                                                                      |
| ------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `gradient-primary`        | `linear-gradient(135deg, #ED713E 0%, #F4A24B 100%)` | Hero icon containers, "first job" celebration (honey blend). It _lightens_ — never under white text.     |
| `gradient-primary-button` | `linear-gradient(135deg, #F2925F 0%, #DB5E2C 100%)` | **Primary CTA button fill — on by default.** Subtle depth; the deeper end keeps white text legible (AA). |
| `gradient-success`        | `linear-gradient(135deg, #22C55E 0%, #16A34A 100%)` | Verified badge backgrounds, completion-confirmed moment                                                  |
| `gradient-dark`           | `linear-gradient(135deg, #1A1A2E 0%, #33334A 100%)` | Dark-mode hero backgrounds, premium-feel cards                                                           |

## Usage rules

### Primary color (#ED713E)

- ✅ Primary CTAs (Publish, Send Code, Accept Offer)
- ✅ Focused input borders
- ✅ Selected category chips
- ✅ Active bottom-nav item
- ✅ Linkable text
- ❌ Body text — too low contrast
- ❌ Large backgrounds — overwhelming, use `primary-50` instead

### Dark color (#1A1A2E)

- ✅ Headlines + body text
- ✅ Secondary CTAs (Save as draft)
- ✅ Bottom nav background (light mode)
- ❌ Replacing pure black — use this for any "dark" intent

### Semantic colors

- ✅ `success` only for verified/completed/positive feedback
- ✅ `warning` only for held funds / pending — not for "watch out" UI
- ✅ `error` only for genuine errors / destructive
- ❌ Don't use semantic colors decoratively — they carry meaning

### Contrast targets

| Combination            | Ratio  | WCAG AA pass?   |
| ---------------------- | ------ | --------------- |
| `primary` on white     | 3.0:1  | Large text only |
| `primary-700` on white | 5.1:1  | ✅ All text     |
| `dark-800` on white    | 14.3:1 | ✅ All text     |
| `dark-400` on white    | 4.6:1  | ✅ All text     |
| White on `primary`     | 3.0:1  | Large text only |
| White on `dark-800`    | 14.3:1 | ✅ All text     |

**Rule:** for any body or label text on the primary color, use white (large text) OR switch to `primary-700` on white for small text.

## Logo

The JOBBees logo is a honeycomb mark (a cluster of orange hexagons) in `primary` (#ED713E), paired with the "JOBBEES" wordmark (the second "B" carries two short antennae — the bee). White outline / subtle shadow for depth.

- Use the orange logo on white / `primary-50` backgrounds
- Use the **white logo** on `primary` / `gradient-primary` backgrounds
- Use the **dark logo** on `dark-50` / light gray backgrounds (rare)

Logo assets live in `apps/mobile/assets/` and should be carried forward from the prototype's `logo.png`, `white-logo.png`, and `icon.png`.

## Implementation references

| Surface               | File                                           |
| --------------------- | ---------------------------------------------- |
| Flutter (mobile)      | `apps/mobile/lib/theme/colors.dart`            |
| Tailwind (admin)      | `apps/admin/app/globals.css`                   |
| Tailwind (web)        | `apps/web/app/globals.css`                     |
| React Native (legacy) | `<old project>/apps/mobile/tailwind.config.js` |

When updating, update all four files + this doc + the `UI-PRINCIPLES.md` companion in this directory.
