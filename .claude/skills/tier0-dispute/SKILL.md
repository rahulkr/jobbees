---
name: tier0-dispute
description: Use whenever the user works on autonomous dispute resolution — the Tier-0 LLM mediator, admin co-pilot brief generation, dispute evidence aggregation, resolution proposals, or escalation logic. Covers prompt engineering, output schema, threshold rules, and PII handling for dispute flows.
---

# Tier-0 dispute mediator skill

## When to invoke

Any of: dispute, mediator, Tier-0, resolution, escalation, admin co-pilot, case brief, dispute proof, evidence aggregation, dispute thread.

## Architecture facts (locked)

### Two LLM agents working in tandem

**Agent 1: Tier-0 Mediator (auto-resolution)**

- Triggers on every new dispute where `disputedAmountCents ≤ TIER0_THRESHOLD_CENTS` (default AUD $200 = 20,000 cents — config-driven)
- Reads the full evidence package: thread messages, completion proof photos (image descriptions, not pixels), job details, cancellation history, payment state
- Proposes one of three resolutions: `FULL_RELEASE_TO_TASKER`, `PARTIAL_RELEASE` (with split %), `REFUND_TO_CLIENT`
- Output is **structured JSON**, validated against a Zod schema before display to users
- Both parties see the proposal in the dispute thread; either can `ACCEPT` (auto-resolve) or `ESCALATE` (human admin)

**Agent 2: Admin Co-pilot (escalation brief)**

- Triggers when dispute is `ESCALATED` (either party rejected Tier-0, or amount > threshold)
- Generates a case brief for the admin reviewing the dispute
- Output: timeline summary, key messages highlighted, evidence summary, precedent from similar past disputes, recommended action with confidence score
- Admin reads, decides, acts — agent does NOT auto-execute the action

### Model selection

- **Claude Sonnet** for both agents (long context, structured reasoning, lower hallucination on legal/financial output than Gemini)
- Fallback to Claude Haiku if cost telemetry alerts on Sonnet spend

### Evidence pipeline

```
disputeId → fetchEvidence() returns:
  - job: { title, description, budgetCents, status, scheduledAt, completedAt }
  - thread: [{ ts, fromRole, fromUserId, contentRedacted, hasAttachment }]
  - completionProof: [{ photoUrl, capturedAt, geoVerified, exifVerified }]
  - cancellations: [{ initiatedBy, reason, ts, fee }]
  - payment: { state, capturedAt, amountCents }
  - reviewsBetweenParties: [{ priorRating, priorText }]
```

**PII redaction** happens BEFORE the evidence is sent to the LLM:

- User names → `Client` / `Tasker`
- Phone numbers / emails → `[REDACTED]`
- Bank details / payment methods → `[REDACTED]`
- Photos → described in text (e.g., "Photo: outdoor scene with timestamp 2026-03-15 14:23"), never raw pixels

### Tier-0 prompt structure (system + user)

System prompt loads from `apps/api/src/modules/disputes/prompts/tier0.system.md` (versioned, audit-logged):

```
You are a marketplace dispute mediator for an Australian job marketplace.
Your role is to propose a fair resolution between a client and a tasker for jobs under AUD $200.
You have access to the dispute evidence below. You must:
1. Read all evidence carefully
2. Determine if the job was completed as agreed
3. Propose ONE of: FULL_RELEASE_TO_TASKER, PARTIAL_RELEASE (specify %), REFUND_TO_CLIENT
4. Justify briefly (max 3 sentences) referencing specific evidence
5. Rate your confidence: HIGH (clear-cut), MEDIUM (some ambiguity), LOW (recommend escalation)

Constraints:
- Apply Australian consumer law principles (reasonable expectations, fair dealing)
- If evidence is materially incomplete, recommend ESCALATE
- If either party shows clear bad-faith behaviour, weight heavily against them
- Never invent facts not in the evidence
- Never reveal PII (even if you somehow see it — refuse and request redaction)
```

User prompt: structured evidence JSON.

### Output schema (Zod-validated)

```ts
const Tier0ProposalSchema = z.object({
  resolution: z.enum(['FULL_RELEASE_TO_TASKER', 'PARTIAL_RELEASE', 'REFUND_TO_CLIENT', 'ESCALATE']),
  partialReleasePercent: z.number().min(0).max(100).optional(), // required if PARTIAL_RELEASE
  rationale: z.string().min(40).max(800),
  evidenceReferences: z.array(z.string()), // e.g. ['thread.msg.124', 'completionProof.photo.2']
  confidence: z.enum(['HIGH', 'MEDIUM', 'LOW']),
  redFlags: z.array(z.string()).optional(), // e.g. ['Tasker provided no completion proof']
});
```

LLM must produce valid JSON. We validate; if invalid, retry once; if still invalid, ESCALATE.

### Admin co-pilot brief schema

```ts
const CaseBriefSchema = z.object({
  timelineSummary: z.string(),
  keyMessages: z.array(
    z.object({
      messageId: z.string(),
      quote: z.string(),
      significance: z.string(),
    }),
  ),
  evidenceSummary: z.string(),
  precedents: z.array(
    z.object({
      disputeId: z.string(),
      similarity: z.string(),
      resolution: z.string(),
    }),
  ),
  recommendedAction: z.enum([
    'FULL_RELEASE_TO_TASKER',
    'PARTIAL_RELEASE',
    'REFUND_TO_CLIENT',
    'REQUEST_MORE_INFO',
    'SUSPEND_USER',
  ]),
  partialReleasePercent: z.number().optional(),
  confidence: z.enum(['HIGH', 'MEDIUM', 'LOW']),
  rationale: z.string(),
});
```

### Precedent retrieval

- Embed the current dispute summary
- Cosine search against past **escalated, admin-resolved** disputes from the same category
- Return top 3 with their resolutions for the co-pilot to consider
- Skip precedent retrieval if fewer than 20 past disputes exist (not enough signal)

## Hard rules — never violate

1. **PII redaction before LLM call — every time.** Use `PiiRedactionService.scrub()` on evidence pre-send.
2. **Output must validate against schema.** Retry once; ESCALATE on second failure.
3. **Never let Tier-0 auto-execute the resolution.** The state transition only fires after **both parties accept**, or one party accepts and the other doesn't respond within 48 hours.
4. **Never let the co-pilot auto-execute.** Admin always reviews and clicks.
5. **Audit log every Tier-0 invocation and outcome.** Track which proposals were accepted, rejected, escalated — feeds future tuning.
6. **Threshold is config-driven** (`TIER0_THRESHOLD_CENTS`). Default 20,000 (AUD $200). Never hardcode.
7. **Cost guardrail per dispute.** Max 3 LLM calls per dispute (Tier-0 once, retry once, co-pilot once on escalation). Telemetry tracks.
8. **Never include user real names in the LLM context.** Already covered by PII redaction.
9. **Prompts versioned in git.** Changing the prompt = new version = new ADR entry.

## File pointers

- `apps/api/src/modules/disputes/tier0.service.ts` — Tier-0 agent
- `apps/api/src/modules/disputes/copilot.service.ts` — admin co-pilot agent
- `apps/api/src/modules/disputes/evidence.service.ts` — evidence aggregation
- `apps/api/src/modules/disputes/prompts/` — versioned prompt files
- `apps/api/src/modules/disputes/schemas/` — Zod schemas for output validation
- `apps/api/src/modules/disputes/precedent.service.ts` — past dispute retrieval
- `apps/api/src/common/pii/pii-redaction.service.ts` — PII scrubber

## Common changes

### Tuning the Tier-0 prompt

1. Edit `prompts/tier0.system.v<N+1>.md` (new version)
2. Update `tier0.service.ts` to use the new version
3. Add an ADR documenting the change rationale
4. Run the eval suite: `pnpm --filter @jobbees/api test:tier0-eval`
5. Don't switch versions in production without an eval comparison

### Adding evidence types

1. Update `evidence.service.ts` `fetchEvidence()` to include the new data
2. Update the PII redaction list for the new fields
3. Update the prompts to mention the new evidence type
4. Update the schema if the LLM needs to reference it

### Adjusting Tier-0 threshold

1. Change `TIER0_THRESHOLD_CENTS` env var
2. Override in admin UI `/admin/config/dispute-threshold`
3. Audit log the change with actor + old value + new value

## Acceptance metrics

Track for product analytics:

- **Tier-0 acceptance rate** — % of proposals where both parties accept (target: 50-70%)
- **Escalation rate** — % of disputes that reach human admin (target: 30-50%)
- **Time-to-resolution** — median wall-clock time from dispute open to resolved
- **Admin override rate** — % of co-pilot recommendations admin disagrees with (high = retrain prompt)
- **Cost per dispute** — average LLM tokens spent (caps cost telemetry)
