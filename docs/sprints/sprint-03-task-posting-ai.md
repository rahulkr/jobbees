# Sprint 3 — Job posting + AI extraction + guest mode

**Dates:** Mon 20 Jul → Fri 31 Jul 2026 (10 working days)
**Theme:** Anyone — logged in OR a curious visitor — can post a job. They type a sentence, take a photo, the AI does the rest, and only at the moment of publish do we ask them to sign up.
**Hours budget:** ~130 (60 mobile, 70 backend) — the largest single AI sprint
**Mid-sprint demo:** Fri 24 Jul
**End-of-sprint demo:** Fri 31 Jul

## Goal in one sentence

By Friday 31 Jul, a **guest user** (no account) can open the app, browse jobs in their area, tap "Post a job", take a photo of a broken fence, see the AI extract a structured draft, tap Publish — and only then get prompted to sign up. The draft survives the signup and posts to their fresh account.

## Scope — inventory rows

### Mobile (apps/mobile)

| ID  | Item                                                    | Call | Hrs | Notes                                                                              |
| --- | ------------------------------------------------------- | ---- | --- | ---------------------------------------------------------------------------------- |
| 53  | Category picker                                         | IN   | 2   |                                                                                    |
| 54  | Title + description (free text)                         | IN   | 1   |                                                                                    |
| 55  | AI extraction confirmation screen (single-pass)         | IN   | 4   | Edit parsed fields before publish                                                  |
| 56  | Multi-turn clarifying questions (ReAct loop)            | IN★  | 7   | Mobile UI: present q one at a time, gather answers, show progress                  |
| 57  | Photo upload (multi-photo)                              | IN   | 3   |                                                                                    |
| 58  | Voice-driven job posting                                | IN   | 14  | Speech-to-text via Gemini audio, voice UI, fallback to text                        |
| 59  | Camera-based job creation (vision model)                | IN★  | 8   | Mobile UI: camera + multi-photo + "identifying..." loading                         |
| 60  | Location / address picker (map + autocomplete)          | IN   | 5   | Google Maps autocomplete + map view (geocoding vendor locked Google Maps Platform) |
| 61  | Map preview                                             | IN   | 2   |                                                                                    |
| 62  | Date / time picker                                      | IN   | 2   |                                                                                    |
| 63  | Duration estimate (AI-suggested)                        | IN   | 1   |                                                                                    |
| 64  | Budget input                                            | IN   | 1   |                                                                                    |
| 65  | Budget AI nudge (LLM-only verbal)                       | THIN | 2   | No ML model; LLM verbalises range                                                  |
| 66  | Special requirements / preferences                      | IN   | 1   |                                                                                    |
| 67  | Review & publish                                        | IN   | 2   |                                                                                    |
| 68  | Save as draft                                           | IN   | 2   |                                                                                    |
| 69  | Resume draft from list                                  | IN   | 1   |                                                                                    |
| 71  | Schedule job within 7d                                  | IN   | 1   |                                                                                    |
| 72  | Schedule job >7d in future                              | IN   | 3   | SetupIntent path (backend in S5)                                                   |
| 74  | Edit posted job (before offer accepted)                 | THIN | 2   |                                                                                    |
| 75  | Cancel/delete posted job                                | IN   | 1   |                                                                                    |
| 523 | **Guest mode — browse home feed without account**       | IN   | 5   | New: route group, read-only chrome, hide offer CTAs                                |
| 524 | **Post-then-signup flow (deferred auth until publish)** | IN   | 6   | New: local draft persistence, "Sign up to publish" modal, auth-on-publish          |

**Mobile total: ~76h (voice + vision are heavy; guest + deferred auth adds 11)**

### Backend (apps/api)

| ID  | Item                                                               | Call | Hrs | Notes                                                                                                      |
| --- | ------------------------------------------------------------------ | ---- | --- | ---------------------------------------------------------------------------------------------------------- |
| 246 | Job CRUD endpoints                                                 | IN   | 6   |                                                                                                            |
| 247 | AI extraction (Gemini Flash JSON-mode)                             | IN   | 6   |                                                                                                            |
| 248 | Clarifying agent loop (ReAct multi-turn)                           | IN★  | 14  | Confidence-scored fields, stop when filled, max 3 follow-ups                                               |
| 249 | Multimodal extraction from images                                  | IN★  | 14  | Gemini Flash vision → Pro fallback; cost guarded                                                           |
| 250 | Image upload + resize + Azure Blob storage                         | IN   | 5   | Local FS at MVP; Blob swap S10                                                                             |
| 251 | Geocoding (Google Maps Platform — locked)                          | IN   | 3   | Server-side proxy of Google Maps geocoding calls so the API key never ships to the client                  |
| 252 | Job state machine                                                  | IN   | 6   | DRAFT → PUBLISHED → OFFERING → ACCEPTED → ...                                                              |
| 253 | Job lifecycle audit log                                            | IN   | 3   |                                                                                                            |
| 254 | Embeddings generation on publish (pgvector)                        | IN★  | 4   | OpenAI text-embedding-3-small (1536-dim)                                                                   |
| 255 | Re-embedding on edit                                               | IN★  | 2   |                                                                                                            |
| 257 | Job draft persistence                                              | IN   | 3   |                                                                                                            |
| 258 | Job search endpoint                                                | IN   | 5   | Text + filters; backend for discovery in S4                                                                |
| 259 | Schedule job >7d backend                                           | IN   | 3   | Mobile UI in S3, SetupIntent in S5                                                                         |
| 260 | Public Q&A under job — backend                                     | IN   | 5   | CRUD, visibility; full UI in S4                                                                            |
| 525 | **Public read endpoints (anonymous browse)**                       | IN   | 4   | New: GET /v1/public/tasks with sensitive-field filter; rate-limited per IP (URL path unchanged at MVP)     |
| 526 | **"Claim draft on signup" — attach pre-auth draft to new account** | IN   | 5   | New: signup endpoint accepts optional draft payload, creates Job with status DRAFT and clientId = new user |

**Backend total: ~88h (guest support adds 9)**

### Schema additions

- Job: already has most fields. Add `extractedFields Json?` (raw vs structured AI extraction snapshot), `embeddingHash String?` for cache validation
- JobPhoto: already in schema
- JobQuestion: already in schema — used in S4 for public Q&A
- New `JobDraft` model OR reuse Job with `status: DRAFT` — go with the latter to keep schema simple
- New `ExtractionLog` model for AI-call cost tracking: `jobId`, `model`, `inputTokens`, `outputTokens`, `costUsd`, `latencyMs`, `createdAt`
- **Guest-mode draft handling: no new model needed.** Mobile keeps the draft in local storage (Hive / shared_preferences) until signup. On signup, mobile POSTs the draft body to the signup endpoint, which creates a Job with `status: DRAFT` + `clientId = newUserId`. Trade-off: draft is lost if the user uninstalls the app before signing up. Acceptable at MVP — user just retypes.

## Design decision — guest mode + deferred auth

**Pattern:** "Show value before asking for commitment." Industry-standard for AU consumer marketplaces (Airtasker, hipages, Oneflare all do this). Industry data: ~20-30% lift in signup conversion vs gated-from-start flow.

**What anonymous users can do:**

- Browse the ranked home feed (read-only)
- Open job detail pages (read-only)
- Use category / location filters
- Run the AI extraction posting flow start-to-finish
- Hit the "Publish" CTA → triggers signup prompt

**What anonymous users CANNOT do:**

- Make an offer (CTA shows "Sign up to make an offer")
- View other users' profiles (returns 401 → "Sign up to view tasker profile")
- Use messaging
- See client contact info
- Access /me/\* endpoints

**Public read endpoint design (`/v1/public/tasks` — URL path unchanged at MVP):**

- Returns job list with: title, description (first 200 chars), category, budget range, suburb (not full address), photo thumbnails, posted-at, status
- Filters out: full address, client email/phone, client full name (only first name + initial)
- Rate-limited at edge (Cloudflare): 60 req/min per IP
- Cached at edge for 60s (since the feed is read-heavy)

**Auth-on-publish flow:**

1. User taps Publish → mobile checks `isAuthenticated`
2. If true: normal publish flow (Sprint 3 happy path)
3. If false: show "Sign up to publish" bottom sheet
4. User picks "Email signup" or "Continue with Google/Apple"
5. After auth completes, mobile re-tries the publish call WITH the draft payload attached
6. Backend creates Job with `clientId = newUserId` and `status = PUBLISHED`
7. User lands on the new job's detail page (their first job — celebratory state)

**Why this isn't deferred to a later sprint:** the posting flow + AI extraction are being built in Sprint 3. Adding guest-mode now is ~20h. Adding it post-Sprint-3 would require revisiting half the posting flow + adding new mobile route groups + retesting AI flows. Cheaper to do it once.

## Definition of done

Same as Sprint 1, plus:

- [ ] Every external LLM call goes through `redactPii()` (skill §F1)
- [ ] Vision calls start with Gemini Flash; only fall back to Pro on confidence < 0.7 (per `.claude/skills/multimodal-extraction/SKILL.md`)
- [ ] Cost guardrails enforced: max 2 vision calls per job posting (in case of fallback), per-user daily cost cap checked
- [ ] AI extraction prompts versioned via `apps/api/src/modules/ai/prompts/` (each prompt is a `.md` file with frontmatter for model + version)
- [ ] Acceptance test: photo of broken fence → category accuracy ≥ 80% on a hand-curated set of 20 test photos (manual eval)

## Friday demo script (end-of-sprint Fri 31 Jul)

6 minute screencast — starts with guest mode to show the funnel uplift:

```
00:00 — "Sprint 3 wrap. AI-heavy sprint, with a UX twist: guest browsing
        + post-then-signup. Let me show you the full funnel."
00:10 — Cold-launch app on a brand-new install. Show: NO login required.
        Lands on the home feed straight away.
00:25 — Browse the ranked feed as guest. Tap a few jobs to see details.
        Notice the "Sign up to make an offer" CTA replaces the offer button.
00:45 — Tap "Post a job" floating action. Choice screen: type / photo / voice.
        Pick photo. Camera launches. Take a photo of a broken fence.
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
        duration). Client can edit any field.
02:30 — Edit description briefly to show editability. Save.
02:40 — Address picker → map autocomplete → confirm pin → confirm.
02:55 — Review & publish screen. Tap Publish.
03:05 — **Bottom sheet appears: "Sign up to publish your job"**.
        Show the user is still anonymous. Pick "Continue with Email".
03:25 — Fill in name, email, mobile. Submit. OTP verify.
03:50 — App returns to the publish flow. Backend creates the job
        attached to the new account. Job lands in "My jobs" with
        status: PUBLISHED. Celebratory state ("Your first job is live!").
04:10 — Demo voice path on the same install. Logged in this time.
        Tap "Voice" → speak: "Need someone to assemble Ikea bed frame
        next Saturday afternoon Bondi, $80 budget".
04:30 — Wait for transcription + extraction → confirmation screen with
        auto-filled fields → Publish (now skipping the signup gate
        because already authed).
04:45 — Save as draft demo. Open drafts list. Resume.
05:00 — Show admin view: jobs list with new jobs appearing, and the
        signup analytics: "1 user signed up via post-then-signup vs 0
        via direct signup since the demo started" — shows the funnel
        working.
05:15 — Show backend logs: prompt versions used, cost per call,
        latency. Show the public read endpoint hits from the guest
        browsing earlier.
05:30 — Coverage report. Stoplight + asks. End.
```

## Risks

| Risk                                                                          | Likelihood | Impact | Mitigation                                                                                                                                                                                 |
| ----------------------------------------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Extraction accuracy < 80% on test set                                         | Medium     | High   | Budget 20% buffer in S3 + S4 for prompt iteration; iterate on the 20-photo test set                                                                                                        |
| ReAct loop infinite/excessive cost                                            | Medium     | High   | Hard cap at 3 follow-up questions; cost guard enforces daily user limit                                                                                                                    |
| Vision model cost spike (vision ~10× text)                                    | High       | Medium | `.claude/skills/multimodal-extraction/SKILL.md` enforces Flash-first; cost guard at ~$X/user/day                                                                                           |
| Voice transcription poor for AU accents                                       | Medium     | Medium | Test against AU speakers early; fallback to text if confidence < 0.5                                                                                                                       |
| Gemini Flash rate limits during peak                                          | Low        | Medium | Implement client-side queue + exponential backoff                                                                                                                                          |
| Google Maps API key in mobile app — security                                  | Low        | Medium | Mobile app uses a separate restricted API key (Android app + iOS bundle ID restrictions); server-side geocoding calls use a different unrestricted key kept in Key Vault. Rotate quarterly |
| Guest browsing exposes PII via public read endpoint                           | Medium     | High   | Strict allow-list of fields returned, redact full address + last name; security-review skill enforces (skill §F)                                                                           |
| Local draft survives across signup but gets duplicated if user signs up twice | Low        | Low    | Clear local draft after successful publish; idempotency key on signup-publish call                                                                                                         |
| Guest-mode rate-limit gets hit by legitimate browse traffic                   | Low        | Low    | 60 req/min/IP is generous; tune after first day in S10                                                                                                                                     |

## Explicitly NOT in scope

- Recurring jobs — DROPPED (inventory row 73)
- Right-to-left text — DROPPED (inventory row 219)
- AI-generated SEO content per job — POST (inventory row 522)
- SEO slug + meta auto-generation — POST (inventory row 256)
- LightGBM ranker — POST (inventory row 269)
- Re-post / clone job — THIN (inventory row 70 — defer to S4 polish)
- Review authenticity scoring — POST (inventory row 326)
- Eval harness — POST (manual eval at MVP — inventory row 371)

## Day-by-day rough plan

| Day          | Mobile                                                                                | Backend                                                                                    |
| ------------ | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Mon 20 (D1)  | Guest-mode route group + read-only chrome. Posting entry point.                       | Job CRUD endpoints + state machine. Public read endpoint scaffold.                         |
| Tue 21 (D2)  | Category picker + text path. Guest "Sign up to make an offer" CTAs.                   | AI extraction (Gemini Flash JSON-mode). Prompt v1. Public read endpoint with field filter. |
| Wed 22 (D3)  | Photo upload (multi). Camera capture.                                                 | Multimodal extraction. Cost guard.                                                         |
| Thu 23 (D4)  | ReAct UI: question-at-a-time, progress.                                               | ReAct backend orchestration. Confidence scoring.                                           |
| Fri 24 (D5)  | Mid-sprint demo + catch-up.                                                           | Same.                                                                                      |
| Mon 27 (D6)  | Location picker + map. Date picker. Local draft persistence (Hive).                   | Geocoding integration. Embedding generation.                                               |
| Tue 28 (D7)  | Confirmation screen + edit fields. **"Sign up to publish" bottom sheet.**             | Image upload + resize + local FS storage. **Claim-draft-on-signup endpoint.**              |
| Wed 29 (D8)  | Voice path scaffolding + transcription UI. **Auth-on-publish flow + draft transfer.** | Voice transcription endpoint (Gemini audio).                                               |
| Thu 30 (D9)  | Save as draft + resume + edit + cancel. Polish.                                       | Job draft persistence. Audit log. Polish.                                                  |
| Fri 31 (D10) | End-of-sprint demo + CSV update.                                                      | Confirm CI green. Tag `sprint-03-end`.                                                     |

## Definition of "shippable"

- [ ] All 23 mobile rows in scope done (21 original + 2 guest-mode)
- [ ] All 16 backend rows done (14 original + 2 public-read + claim-draft)
- [ ] Photo job posting end-to-end works on iOS sim + Android emulator
- [ ] Voice job posting end-to-end works
- [ ] **Guest cold-launch → browse → post → AI extraction → "Sign up to publish" → fresh-user signup → job lands attached to new account, end-to-end**
- [ ] **Public read endpoint test: anonymous GET returns sanitised job list, never leaks full addresses or PII (skill §F4)**
- [ ] **Rate limit test: anonymous browse 100 req/min from one IP → 429 after 60**
- [ ] Eval set of 20 photos: ≥80% correct category, ≥70% correct duration estimate
- [ ] Cost per job posting ≤ $0.05 average across the eval set
- [ ] `./scripts/coverage.sh` reports ~40% MVP (extra 4 rows lifts the percentage slightly)
- [ ] Sprint 4 detail doc reviewed

## Expected PRs (~16-18)

- `feat(prisma): Job extractedFields + embedding columns finalised + ExtractionLog`
- `feat(api/jobs): Job CRUD + state machine`
- `feat(api/ai): extraction wrapper + PII redaction + cost guard`
- `feat(api/ai): Gemini Flash JSON-mode extraction (text path)`
- `feat(api/ai): multimodal vision extraction (Flash → Pro fallback)`
- `feat(api/ai): ReAct multi-turn clarifying agent loop`
- `feat(api/ai): voice transcription via Gemini audio`
- `feat(api/jobs): image upload + resize + local FS storage`
- `feat(api/jobs): geocoding (Google Maps Platform — server-side proxy)`
- `feat(api/jobs): embedding generation on publish (pgvector)`
- `feat(api/jobs): job draft persistence + edit/cancel`
- `feat(api/jobs): public Q&A backend (CRUD, visibility)`
- **`feat(api/jobs): public read endpoint + field-filter + rate-limit (anonymous browse)`**
- **`feat(api/auth): claim-draft-on-signup — accept optional draft payload, attach to new user`**
- `feat(mobile): guest-mode route group + read-only chrome + "Sign up to make an offer" CTAs`
- `feat(mobile): posting entry + category picker + photo path`
- `feat(mobile): vision extraction UI + ReAct question flow`
- `feat(mobile): voice posting UI + transcription`
- `feat(mobile): confirmation screen + location picker + drafts`
- **`feat(mobile): "Sign up to publish" bottom sheet + local draft persistence + auth-on-publish flow`**
