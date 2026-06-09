---
name: multimodal-extraction
description: Use whenever the user works on extracting structured task fields from poster-uploaded photos — vision model integration, camera-based task creation, image preprocessing, vision prompt engineering, merging vision output with text extraction, fallback logic. Covers model tier selection, schema validation, cost guardrails, and the image-pipeline.
---

# Multimodal task extraction skill

## When to invoke

Any of: multimodal, vision, image extraction, camera task, photo-to-task, vision model, Gemini vision, GPT-4o vision, infer scope from image, infer materials from image, image preprocessing for LLM, vision prompt, vision schema.

## Architecture facts (locked)

### Model selection (tier-driven, not name-locked)

| Use                                                 | Primary model                                                                     | Fallback model                                       | Why                                                           |
| --------------------------------------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| Image extraction                                    | **Flash tier** (currently Gemini 2.5 Flash; whichever fast multimodal is current) | **Pro tier** (Gemini 2.5 Pro / Claude Sonnet vision) | 90%+ accuracy on common AU marketplace tasks at <$0.001/image |
| Edge cases (very ambiguous scene, fallback trigger) | **Pro tier**                                                                      | None — escalate to text-only extraction              | Cost-justified only when Flash returns low confidence         |

**Never use Opus / GPT-4 Turbo for this task.** Cost is 30–100× higher; accuracy gain on this domain is marginal. Reserved for nuanced dispute reasoning, not visual classification.

Model names are config-driven, not hardcoded:

```
VISION_PRIMARY_MODEL=gemini-2.5-flash
VISION_FALLBACK_MODEL=gemini-2.5-pro
VISION_CONFIDENCE_THRESHOLD=0.7
```

When the AI landscape shifts (new Gemini version, OpenAI cheaper option, etc.), update the env var. No code changes.

### Pipeline overview

```
Poster uploads 1–4 photos
  ↓
Azure Content Safety scan (each image)              ← rejects NSFW/violence BEFORE vision call
  ↓
Image preprocessing (resize, EXIF strip selectively, hash)
  ↓
Cache lookup by content hash                         ← avoids duplicate calls on retry
  ↓
Vision LLM call (Flash tier, structured output)
  ↓
Zod schema validation
  ↓
If valid + confidence ≥ 0.7 → return
If valid + confidence < 0.7 → fallback to Pro tier → re-validate
If invalid both passes → fall back to text-only extraction + flag for admin review
  ↓
Merge with text extraction (if poster also typed a description)
  ↓
Return to mobile for poster confirmation
```

### Image preprocessing rules

1. **Resize**: longest edge max 1024 px, JPEG quality 85. Cuts vision tokens ~3× without measurable accuracy loss. Run via `sharp` in the worker.
2. **EXIF**:
   - For **task-creation photos** (the poster's "here's what I want done"): **strip EXIF before sending to vision API**. Privacy-protective — don't leak GPS/timestamp/device to the LLM provider.
   - For **completion-proof photos** (the tasker's "here's what I did"): keep EXIF for the tampering check (separate concern, see Trust & Safety §2.12). Vision extraction doesn't run on completion proof — that's the EXIF check, not vision.
3. **Hash**: SHA-256 of the _preprocessed_ bytes. Used as the cache key. Re-uploading the same image returns cached extraction with no new API call.
4. **Max 4 images per task**: hard limit. More images don't improve extraction quality and balloon cost. Mobile UI enforces.

### Output schema (Zod-validated)

```ts
const VisionExtractionSchema = z.object({
  category: z.enum([
    'cleaning',
    'moving',
    'handyman',
    'gardening',
    'assembly',
    'errands',
    'tech-help',
    'pet-care',
    'unknown', // explicit "I can't tell" signal — triggers fallback or admin flag
  ]),
  scope: z.string().min(10).max(500),
  materials: z.array(z.string()).max(20),
  durationHours: z.number().min(0.5).max(24),
  riskClass: z.enum(['low', 'medium', 'high']),
  riskFactors: z.array(z.string()).max(5).optional(), // e.g. ['working at height', 'electrical', 'asbestos suspected']
  confidence: z.number().min(0).max(1),
  notes: z.string().max(300).optional(), // anything ambiguous worth flagging to poster
});
```

LLM must produce valid JSON matching this schema. Retry once on validation failure; if still invalid, escalate to text-only extraction and log the failure for prompt tuning.

### Prompt structure

System prompt lives at `apps/api/src/modules/tasks/prompts/vision-extraction.system.v1.md` (versioned):

```
You are a task scoping assistant for an Australian peer-to-peer marketplace.

Given 1-4 photos a poster has uploaded, extract structured information about the task they want done. Output STRICT JSON matching the schema provided.

Rules:
1. Read all images. Treat them as different views of the same task unless clearly distinct.
2. Estimate duration based on what a typical paid worker would charge for. Round to 0.5h increments.
3. Risk class:
   - LOW: indoor light cleaning, errands, basic assembly, tech help
   - MEDIUM: outdoor work, moving heavy items, basic gardening, basic handyman
   - HIGH: working at heights (>2m), electrical, plumbing, anything near gas, asbestos, structural
4. Be honest about uncertainty. If you can't tell from the images, use category="unknown" and explain in notes.
5. Materials = only list what the TASKER will need to bring/buy. Don't list things already visible at the location.
6. Confidence: 1.0 = certain; 0.5 = guessing; 0.0 = no idea. Calibrate honestly — over-confidence will cause bad bids.

Apply Australian context where relevant (e.g. "shed" not "garage" for backyard structures; "verandah" not "porch"; AUD pricing implicit).

Refuse and return category="unknown" + low confidence if images show: nudity, violence, illegal activity, or content unrelated to a real-world task. (Content Safety should have filtered these earlier — this is a defence-in-depth check.)
```

User prompt: just the images, attached via the provider's vision API.

### Merging with text extraction

When the poster uploads photos AND types a description, run both extractions independently, then merge:

| Field           | Source of truth                                                                       | Rationale                                                    |
| --------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `title`         | Text extraction                                                                       | Posters phrase their own titles better than vision can infer |
| `description`   | Text extraction                                                                       | Same                                                         |
| `category`      | Vision (override text only if vision confidence ≥ 0.85)                               | Vision is better at recognising what's actually in the photo |
| `scope`         | Vision augments text — concatenate as "Poster says: [text]. Photos suggest: [vision]" | Both useful for the tasker                                   |
| `materials`     | Union of both, deduplicated                                                           | Vision catches things posters forget to mention              |
| `durationHours` | Average of both, weighted by confidence                                               | Posters underestimate; vision is more realistic              |
| `riskClass`     | Max of both (more conservative wins)                                                  | Safety bias                                                  |
| `riskFactors`   | Union                                                                                 |                                                              |
| `budget`        | Poster only (never AI-derived without explicit nudge UI)                              | Tax/legal implications                                       |

When poster provides only photos: vision result is the canonical extraction. Mobile UI shows fields pre-filled, poster confirms or edits before publish.

When poster provides only text: vision pipeline doesn't run. Text extraction handles it.

## Hard rules — never violate

1. **Never call vision API in a request path.** Always async via BullMQ (`extract-from-images.processor.ts`). Mobile UI shows "Identifying…" loading state for ~3–5 seconds, then renders the form pre-filled.
2. **Always preprocess images first.** Resize + JPEG-85 + EXIF strip (task-creation only) BEFORE sending to LLM. Saves ~70% of vision-token cost.
3. **Cache by content hash.** Re-uploading the same image must not trigger a second API call. Cache TTL: 7 days (after that, content is probably edited or stale).
4. **Run Azure Content Safety FIRST.** Vision extraction only runs on images that passed content moderation. NSFW/violent images never hit the LLM — they're rejected at upload.
5. **PII redaction for non-image context.** If you pass the poster's typed description alongside the images (for joint extraction), redact PII via `PiiRedactionService.scrub()` first.
6. **Schema validation is mandatory.** Retry once if invalid; fall back to text-only on second failure. Never accept unstructured LLM output.
7. **Cost guardrail per task.** Max 2 vision calls per task posting (primary + fallback). Hard cap, enforced in `LlmService`. Exceeded calls return cached/text-only extraction.
8. **Confidence threshold drives fallback.** `confidence < 0.7` → escalate to Pro tier. `confidence < 0.4` even after Pro → flag for admin review + use text-only.
9. **No real names in prompts.** Schema doesn't ask for them and the LLM doesn't see them — vision input is image bytes only.
10. **Prompts are versioned in git.** New prompt version = new file (`vision-extraction.system.v2.md`) + ADR entry + side-by-side eval before switching production traffic.

## File pointers

- `apps/api/src/modules/tasks/vision-extraction.service.ts` — the orchestrator
- `apps/api/src/modules/tasks/prompts/vision-extraction.system.v1.md` — versioned system prompt
- `apps/api/src/modules/tasks/schemas/vision-extraction.schema.ts` — Zod schema
- `apps/api/src/jobs/extract-from-images.processor.ts` — BullMQ worker
- `apps/api/src/modules/ai/llm.service.ts` — provider abstraction (Gemini, Anthropic, OpenAI)
- `apps/api/src/modules/ai/image-preprocess.service.ts` — sharp-based resize + EXIF strip + hash
- `apps/api/src/modules/ai/embedding-cache.service.ts` — content-hash cache (already exists for embeddings; reuse)
- `apps/api/src/modules/trust/content-safety.service.ts` — Azure Content Safety; must run before vision
- `packages/prisma/schema.prisma` — `TaskPhoto` (stores blobUrl + exifJson + moderation), `Task.extractedFields` (Json)

## Common tasks

### Adding a new field to extract

1. Update `VisionExtractionSchema` (the Zod schema)
2. Update the system prompt: bump to `v<N+1>.md`, add the new field's instructions
3. Update `vision-extraction.service.ts` to wire the new field
4. Add a test case using the eval harness
5. Document the change in an ADR

### Switching the vision model

1. Update env vars: `VISION_PRIMARY_MODEL`, `VISION_FALLBACK_MODEL`
2. No code changes required — `LlmService` reads from config
3. Run the eval harness against both old and new model before flipping production traffic
4. Roll out via feature flag (env var per env)

### Tuning the confidence threshold

1. Change `VISION_CONFIDENCE_THRESHOLD` in admin config
2. Observe fallback-rate metric — too low = fallback never fires (Flash errors slip through); too high = expensive Pro tier fires too often
3. Target: ~10–15% fallback rate at MVP scale

### Handling a new image format

1. Update `image-preprocess.service.ts` to handle the new mime type (e.g. HEIC, WebP, AVIF)
2. Convert to JPEG before the vision call (most providers accept JPEG most reliably)
3. Test against the eval harness

## Cost guardrails

| Control                     | Threshold                  | Action                                              |
| --------------------------- | -------------------------- | --------------------------------------------------- |
| Per-task vision call cap    | 2                          | Hard limit — primary + 1 fallback                   |
| Per-user daily vision calls | 50                         | Throttle; suggest user contacts support if hit      |
| Daily LLM spend anomaly     | 1.5× rolling 14-day median | Alert; investigate                                  |
| Cache hit rate              | >40% expected at scale     | If <20%, suspect cache key bug or excessive retries |

## Acceptance metrics

Track for product analytics:

- **Extraction accuracy** — % of vision extractions that the poster accepts without editing critical fields (category, durationHours)
- **Fallback rate** — % of extractions that escalate to Pro tier
- **Schema-fail rate** — % of LLM outputs that fail Zod validation (target: <2%)
- **Time-to-extraction** — median wall-clock from photo upload to form prefill (target: <5s)
- **Cost per extraction** — average tokens × price per call (track Flash + Pro separately)
- **Category drift** — % of extractions where vision and text extraction disagree on category (high = model + prompt mismatch)

## Eval harness (when you build it)

For each major prompt or model change, run against a hand-labelled set of ~50 task images covering:

- All 8 categories (6+ examples each)
- High / medium / low risk
- Indoor / outdoor / mixed
- Single image vs multi-image tasks
- Edge cases: blurry photos, irrelevant photos, mixed-content photos

Compare extraction outputs to ground-truth labels. Precision/recall per field. Accept only if all fields beat the prior version by ≥1% with no regression on any field.

## Mobile UI contract

After backend extraction completes, mobile shows the prefilled task form with:

- Photo carousel at top
- Category dropdown (prefilled, editable)
- Scope text (prefilled, editable)
- Materials chips (prefilled, removable, addable)
- Duration slider (prefilled at vision's estimate)
- Risk class indicator (prefilled, editable)
- **A confirmation step**: poster must explicitly confirm before publish. Never auto-publish from vision extraction — always human-in-the-loop.

If vision confidence is low (<0.5 even after Pro fallback), mobile shows a banner: "We couldn't read the photos well — please fill in the details below."

## What this skill does NOT cover

- EXIF tampering / completion-proof verification — that's a separate concern, see `apps/api/src/modules/trust/exif-check.service.ts` (or a future `.claude/skills/exif-verification/` skill)
- Voice-driven task posting — different pipeline (speech-to-text → text extraction, not images)
- Content moderation — handled by Azure Content Safety BEFORE this pipeline (see `content-safety.service.ts`)
- Tasker profile photos — those don't get vision extraction; just stored + moderated
