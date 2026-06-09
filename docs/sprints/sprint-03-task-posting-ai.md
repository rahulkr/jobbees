# Sprint 3 — Task posting + AI extraction

**Dates:** Mon 13 Jul → Fri 24 Jul 2026 (10 working days)
**Theme:** A poster types a sentence, takes a photo, the AI does the rest — category, budget range, clarifying questions, structured task draft, publish.
**Hours budget:** ~110 (50 mobile, 60 backend) — the largest single AI sprint
**Mid-sprint demo:** Fri 17 Jul
**End-of-sprint demo:** Fri 24 Jul

## Goal in one sentence

By Friday 24 Jul, a poster takes a photo of a broken fence, types "fix this", and the app comes back with: category (handyman/fences), budget range $200-350, three clarifying questions, structured task fields filled in, ready to publish.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 53 | Category picker | IN | 2 | |
| 54 | Title + description (free text) | IN | 1 | |
| 55 | AI extraction confirmation screen (single-pass) | IN | 4 | Edit parsed fields before publish |
| 56 | Multi-turn clarifying questions (ReAct loop) | IN★ | 7 | Mobile UI: present q one at a time, gather answers, show progress |
| 57 | Photo upload (multi-photo) | IN | 3 | |
| 58 | Voice-driven task posting | IN | 14 | Speech-to-text via Gemini audio, voice UI, fallback to text |
| 59 | Camera-based task creation (vision model) | IN★ | 8 | Mobile UI: camera + multi-photo + "identifying..." loading |
| 60 | Location / address picker (map + autocomplete) | IN | 5 | Mapbox autocomplete + map view |
| 61 | Map preview | IN | 2 | |
| 62 | Date / time picker | IN | 2 | |
| 63 | Duration estimate (AI-suggested) | IN | 1 | |
| 64 | Budget input | IN | 1 | |
| 65 | Budget AI nudge (LLM-only verbal) | THIN | 2 | No ML model; LLM verbalises range |
| 66 | Special requirements / preferences | IN | 1 | |
| 67 | Review & publish | IN | 2 | |
| 68 | Save as draft | IN | 2 | |
| 69 | Resume draft from list | IN | 1 | |
| 71 | Schedule task within 7d | IN | 1 | |
| 72 | Schedule task >7d in future | IN | 3 | SetupIntent path (backend in S5) |
| 74 | Edit posted task (before bid accepted) | THIN | 2 | |
| 75 | Cancel/delete posted task | IN | 1 | |

**Mobile total: ~65h (voice + vision are heavy)**

### Backend (apps/api)

| ID | Item | Call | Hrs | Notes |
| --- | --- | --- | --- | --- |
| 246 | Task CRUD endpoints | IN | 6 | |
| 247 | AI extraction (Gemini Flash JSON-mode) | IN | 6 | |
| 248 | Clarifying agent loop (ReAct multi-turn) | IN★ | 14 | Confidence-scored fields, stop when filled, max 3 follow-ups |
| 249 | Multimodal extraction from images | IN★ | 14 | Gemini Flash vision → Pro fallback; cost guarded |
| 250 | Image upload + resize + Azure Blob storage | IN | 5 | Local FS at MVP; Blob swap S10 |
| 251 | Geocoding (Mapbox or Google) | IN | 3 | |
| 252 | Task state machine | IN | 6 | DRAFT → PUBLISHED → BIDDING → ACCEPTED → ... |
| 253 | Task lifecycle audit log | IN | 3 | |
| 254 | Embeddings generation on publish (pgvector) | IN★ | 4 | OpenAI text-embedding-3-small (1536-dim) |
| 255 | Re-embedding on edit | IN★ | 2 | |
| 257 | Task draft persistence | IN | 3 | |
| 258 | Task search endpoint | IN | 5 | Text + filters; backend for discovery in S4 |
| 259 | Schedule task >7d backend | IN | 3 | Mobile UI in S3, SetupIntent in S5 |
| 260 | Public Q&A under task — backend | IN | 5 | CRUD, visibility; full UI in S4 |

**Backend total: ~79h**

### Schema additions

- Task: already has most fields. Add `extractedFields Json?` (raw vs structured AI extraction snapshot), `embeddingHash String?` for cache validation
- TaskPhoto: already in schema
- TaskQuestion: already in schema — used in S4 for public Q&A
- New `TaskDraft` model OR reuse Task with `status: DRAFT` — go with the latter to keep schema simple
- New `ExtractionLog` model for AI-call cost tracking: `taskId`, `model`, `inputTokens`, `outputTokens`, `costUsd`, `latencyMs`, `createdAt`

## Definition of done

Same as Sprint 1, plus:

- [ ] Every external LLM call goes through `redactPii()` (skill §F1)
- [ ] Vision calls start with Gemini Flash; only fall back to Pro on confidence < 0.7 (per `.claude/skills/multimodal-extraction/SKILL.md`)
- [ ] Cost guardrails enforced: max 2 vision calls per task posting (in case of fallback), per-user daily cost cap checked
- [ ] AI extraction prompts versioned via `apps/api/src/modules/ai/prompts/` (each prompt is a `.md` file with frontmatter for model + version)
- [ ] Acceptance test: photo of broken fence → category accuracy ≥ 80% on a hand-curated set of 20 test photos (manual eval)

## Friday demo script (end-of-sprint Fri 24 Jul)

5 minute screencast:

```
00:00 — "Sprint 3 wrap. This is the AI-heavy sprint. Watch."
00:15 — Open app as poster. Tap "Post a task" floating action.
00:25 — Choice screen: type, photo, voice. Tap "Photo".
00:40 — Camera launches. Take a photo of a real broken fence (have one
        ready in the office for the demo).
00:55 — "Identifying..." loading spinner with progress text.
01:10 — Result screen: "I see a damaged fence. Suggested category:
        Handyman → Fences. Estimated budget: $200–350. Want me to ask
        a few clarifying questions?" Tap Yes.
01:30 — ReAct loop, question 1: "How many panels are damaged?" Answer.
01:45 — Question 2: "Do you supply materials, or should the tasker?"
        Answer.
01:55 — Question 3: "When do you need this done by?" Answer.
02:10 — Confirmation screen with extracted fields auto-filled (title,
        description, category, budget, location, scheduled date,
        duration). Poster can edit any field.
02:30 — Edit description briefly to show editability. Save.
02:40 — Address picker → map autocomplete → confirm pin → confirm.
02:55 — Review & publish screen. Tap Publish.
03:05 — Task appears in poster's "My tasks" list with status: PUBLISHED.
03:15 — Back out → repeat the flow using voice input. Tap "Voice" →
        speak: "Need someone to assemble Ikea bed frame next Saturday
        afternoon Bondi, $80 budget".
03:35 — Wait for transcription + extraction → confirmation screen with
        auto-filled fields.
03:50 — Save as draft. Open drafts list. Resume.
04:00 — Show admin view: tasks list with new tasks appearing.
04:10 — Show backend logs: prompt versions used, cost per call,
        latency.
04:25 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Extraction accuracy < 80% on test set | Medium | High | Budget 20% buffer in S3 + S4 for prompt iteration; iterate on the 20-photo test set |
| ReAct loop infinite/excessive cost | Medium | High | Hard cap at 3 follow-up questions; cost guard enforces daily user limit |
| Vision model cost spike (vision ~10× text) | High | Medium | `.claude/skills/multimodal-extraction/SKILL.md` enforces Flash-first; cost guard at ~$X/user/day |
| Voice transcription poor for AU accents | Medium | Medium | Test against AU speakers early; fallback to text if confidence < 0.5 |
| Gemini Flash rate limits during peak | Low | Medium | Implement client-side queue + exponential backoff |
| Mapbox API key in mobile app — security | Low | Medium | Use Mapbox public token restricted by URL/domain; rotate quarterly |

## Explicitly NOT in scope

- Recurring tasks — DROPPED (inventory row 73)
- Right-to-left text — DROPPED (inventory row 219)
- AI-generated SEO content per task — POST (inventory row 522)
- SEO slug + meta auto-generation — POST (inventory row 256)
- LightGBM ranker — POST (inventory row 269)
- Re-post / clone task — THIN (inventory row 70 — defer to S4 polish)
- Review authenticity scoring — POST (inventory row 326)
- Eval harness — POST (manual eval at MVP — inventory row 371)

## Day-by-day rough plan

| Day | Mobile | Backend |
| --- | --- | --- |
| Mon 13 (D1) | Posting entry point + choice screen. | Task CRUD endpoints + state machine. |
| Tue 14 (D2) | Category picker + text path scaffolding. | AI extraction (Gemini Flash JSON-mode). Prompt v1. |
| Wed 15 (D3) | Photo upload (multi). Camera capture. | Multimodal extraction. Cost guard. |
| Thu 16 (D4) | ReAct UI: question-at-a-time, progress. | ReAct backend orchestration. Confidence scoring. |
| Fri 17 (D5) | Mid-sprint demo + catch-up. | Same. |
| Mon 20 (D6) | Location picker + map. Date picker. | Geocoding integration. Embedding generation. |
| Tue 21 (D7) | Confirmation screen + edit fields. | Image upload + resize + local FS storage. |
| Wed 22 (D8) | Voice path scaffolding + transcription UI. | Voice transcription endpoint (Gemini audio). |
| Thu 23 (D9) | Save as draft + resume + edit + cancel. Polish. | Task draft persistence. Audit log. Polish. |
| Fri 24 (D10) | End-of-sprint demo + CSV update. | Confirm CI green. Tag `sprint-03-end`. |

## Definition of "shippable"

- [ ] All 21 mobile rows in scope done
- [ ] All 14 backend rows done
- [ ] Photo task posting end-to-end works on iOS sim + Android emulator
- [ ] Voice task posting end-to-end works
- [ ] Eval set of 20 photos: ≥80% correct category, ≥70% correct duration estimate
- [ ] Cost per task posting ≤ $0.05 average across the eval set
- [ ] `./scripts/coverage.sh` reports ~38% MVP
- [ ] Sprint 4 detail doc reviewed

## Expected PRs (~14-16)

- `feat(prisma): Task extractedFields + embedding columns finalised + ExtractionLog`
- `feat(api/tasks): Task CRUD + state machine`
- `feat(api/ai): extraction wrapper + PII redaction + cost guard`
- `feat(api/ai): Gemini Flash JSON-mode extraction (text path)`
- `feat(api/ai): multimodal vision extraction (Flash → Pro fallback)`
- `feat(api/ai): ReAct multi-turn clarifying agent loop`
- `feat(api/ai): voice transcription via Gemini audio`
- `feat(api/tasks): image upload + resize + local FS storage`
- `feat(api/tasks): geocoding (Mapbox)`
- `feat(api/tasks): embedding generation on publish (pgvector)`
- `feat(api/tasks): task draft persistence + edit/cancel`
- `feat(api/tasks): public Q&A backend (CRUD, visibility)`
- `feat(mobile): posting entry + category picker + photo path`
- `feat(mobile): vision extraction UI + ReAct question flow`
- `feat(mobile): voice posting UI + transcription`
- `feat(mobile): confirmation screen + location picker + drafts`
