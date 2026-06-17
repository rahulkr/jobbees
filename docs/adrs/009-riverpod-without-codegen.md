# ADR-009: Riverpod without code-gen (for now)

**Status:** 🟡 Pragmatic interim — revisit when the build_runner conflict clears
**Date:** 2026-06-17
**Decider:** Engineering lead
**Supersedes:** none

## Context

`apps/mobile/CLAUDE.md` rule 4 says: _"Riverpod for ALL state... use `@riverpod`
code-gen syntax, not the legacy provider syntax. Run build_runner after provider
edits."_

The Flutter Web foundation work (FW-01..03, Sprint 1) introduces the first
Riverpod providers (`dioProvider`, `accessTokenProvider`, `routerProvider`).
When wiring `@riverpod` code-gen, dependency resolution fails:

```
widgetbook_generator 3.21.0  → build_runner ^2.15.0 → build ^4.0.0
riverpod_generator   2.6.x   → build ^2.0.0
=> version solving failed
```

The UI layer (Widgetbook, shipped in PR #10) pins `build_runner` 2.15
(`build ^4.0.0`). Stable `riverpod_generator` (2.6.x) still depends on
`build ^2.0.0`. The only `riverpod_generator` that supports `build 4.x` is
`3.0.0-dev.*` — a pre-release.

Root CLAUDE.md rule 13 forbids pulling in pre-release / major dependency bumps
without an ADR and isolated testing. So adopting `@riverpod` today would mean
shipping a pre-release generator across the whole app — not acceptable for a
foundation PR.

## Decision

Use **modern, non-code-gen Riverpod** for now:

- `NotifierProvider` + `Notifier<T>` for mutable state (e.g. `accessTokenProvider`).
- `Provider<T>` for derived / infra singletons (e.g. `dioProvider`, `routerProvider`).

This is explicitly **not** the legacy syntax rule 4 warns against
(`StateNotifierProvider`, `ChangeNotifierProvider`, `StateProvider`). It is the
current first-class runtime API; `@riverpod` code-gen merely generates this same
shape.

## Consequences

- ✅ No pre-release deps; clean `flutter pub get`; CI (which runs no build_runner
  step) needs no generated files committed.
- ✅ Migration to `@riverpod` later is mechanical and provider-by-provider — the
  public provider names (`dioProvider`, etc.) stay identical.
- ⚠️ Slightly more boilerplate than the annotation form.
- ⚠️ No `riverpod_lint`/`custom_lint` enforcement until code-gen is adopted.

## Revisit when

Any one of:

1. `riverpod_generator` ships a stable release supporting `build 4.x`, **or**
2. `widgetbook_generator` relaxes its `build_runner` pin, **or**
3. Widgetbook is moved to a separate build target so its generator no longer
   constrains the app's `build_runner` version.

At that point: add `riverpod_annotation` + `riverpod_generator`, convert the
providers to `@riverpod`, wire a `build_runner` regeneration check into the
Flutter CI job, and update rule 4's "Run build_runner" guidance accordingly.
