---
name: pgvector-match
description: Use whenever the user works on matching, ranked feed, semantic search, embeddings, vector similarity, pgvector, or the discovery feed algorithm. Covers embedding model choice, cosine query patterns, ranked-feed weighted blend, and combining vector + deterministic signals.
---

# pgvector matching skill

## When to invoke

Any of: matching, ranked feed, semantic search, embeddings, vector, pgvector, cosine, top-K, discovery, recommendation, similarity, find-similar-tasks, find-similar-taskers.

## Architecture facts (locked)

### Embedding model
- **OpenAI `text-embedding-3-small`** (1536 dimensions)
- Chosen because: small (fast), cheap ($0.02/1M tokens), good quality, ubiquitous tooling
- Do NOT swap to a different model without re-embedding everything (vector spaces are not compatible across models)

### What we embed
- **Task:** `title + "\n\n" + description + "\nCategory: " + category.name + "\nSkills: " + skillsList.join(", ")` → 1 embedding per task
- **Tasker profile:** `bio + "\nSkills: " + skills.join(", ") + "\nCompleted: " + recentJobTitles.join(", ")` → 1 embedding per tasker
- **Recomputed on edit** of any included field (task description change → re-embed task)

### Storage
- `Task.embedding` column with `Unsupported("vector(1536)")` in Prisma schema
- `TaskerProfile.embedding` same
- **HNSW index** on each (not IVFFlat — HNSW is faster for our scale, no re-train needed as data grows):
  ```sql
  CREATE INDEX task_embedding_hnsw ON "Task" USING hnsw (embedding vector_cosine_ops);
  CREATE INDEX tasker_embedding_hnsw ON "TaskerProfile" USING hnsw (embedding vector_cosine_ops);
  ```

### Query pattern (cosine similarity)

Prisma doesn't support pgvector natively. Use `$queryRaw`:

```ts
const matches = await prisma.$queryRaw<TaskMatch[]>`
  SELECT
    id,
    title,
    "budgetCents",
    1 - (embedding <=> ${queryEmbedding}::vector) AS similarity,
    ST_Distance(
      ST_MakePoint(longitude, latitude)::geography,
      ST_MakePoint(${userLon}, ${userLat})::geography
    ) AS distance_metres
  FROM "Task"
  WHERE
    "deletedAt" IS NULL
    AND "status" = 'BIDDING'
    AND "countryCode" = ${countryCode}
    AND (embedding <=> ${queryEmbedding}::vector) < 0.6  -- distance threshold
  ORDER BY embedding <=> ${queryEmbedding}::vector
  LIMIT 50
`;
```

The `<=>` operator is cosine distance (0 = identical, 1 = orthogonal, 2 = opposite). `1 - distance` = cosine similarity.

### Ranked feed — weighted blend

After top-50 semantic retrieval, re-rank deterministically:

```
finalScore =
    0.45 * cosineSimilarity         (semantic relevance)
  + 0.25 * proximityScore           (distance: 0–10km = 1.0, 10–25km = 0.6, 25–50km = 0.3, >50km = 0)
  + 0.15 * recencyScore             (hours since post: 0–1h = 1.0, 1–6h = 0.8, 6–24h = 0.5, >24h = 0.3)
  + 0.10 * budgetAlignment          (budget vs tasker's stated rate range — 1.0 if within ±20%, 0.5 if ±40%, 0 if outside)
  + 0.05 * categoryMatch            (1.0 if exact category, 0.5 if related category, 0 otherwise)
```

Weights are **config-driven** — admin can adjust in `/admin/config/ranking-weights`. Hand-tuned at MVP; LightGBM ranker is POST.

### Top-K return
- Mobile home feed: return top 20 after re-rank
- Auto-invite trigger: notify top 10 matched taskers on every task publish
- Search bar: full pgvector index, no rerank, return top 50

## Hard rules — never violate

1. **Never call the OpenAI embedding API in a request path** (synchronous request from mobile). Always async — write to a BullMQ queue, mobile sees stale data for ~5 seconds.
2. **Always batch embedding calls when possible.** Single API call for 100 tasks is way cheaper than 100 individual calls.
3. **Always re-embed on edit of included fields.** Title, description, skills, category — if any change, re-embed.
4. **Never query embeddings without a filter.** Always include `deletedAt IS NULL` and `countryCode` and a `status` filter.
5. **Never store the raw API response.** Just the vector + a checksum of the source content (lets us detect when re-embedding is needed).
6. **Cache embeddings by content hash.** Same input → same embedding. `EmbeddingCacheService.get(contentHash)`.
7. **Embedding dimension is locked at 1536.** Migration to a different dimension = re-embed everything.
8. **Always use HNSW index**, never IVFFlat (IVFFlat needs retraining as data scales).
9. **Distance threshold of 0.6** filters obvious mismatches. Tune with eval data, not vibes.

## File pointers

- `apps/api/src/modules/matching/embedding.service.ts` — generates + caches embeddings
- `apps/api/src/modules/matching/match.service.ts` — query + rerank
- `apps/api/src/modules/matching/match.controller.ts` — REST endpoints
- `apps/api/src/modules/matching/ranking-weights.config.ts` — config-driven weights
- `apps/api/src/jobs/embed-task.processor.ts` — BullMQ worker
- `packages/prisma/schema.prisma` — `Task.embedding`, `TaskerProfile.embedding`

## Common tasks

### Adding a new feature to the embedding input
1. Update `formatTaskForEmbedding()` in `embedding.service.ts`
2. Bump the embedding version (e.g., `embeddingVersion: 2`)
3. Run a backfill job to re-embed all existing tasks at the new version
4. Old + new versions coexist during migration; query by latest version

### Tuning ranking weights
1. Edit `ranking-weights.config.ts` defaults
2. Override in admin UI for production tuning
3. Log every ranked feed query with the weights used (for A/B analysis later)

### Adding a new ranking signal
1. Compute the signal in `match.service.ts`
2. Add weight to the config + admin UI
3. Document the signal in `docs/adrs/<next>-ranking-signal.md`
4. Backfill is not needed — signal applies immediately to new queries
