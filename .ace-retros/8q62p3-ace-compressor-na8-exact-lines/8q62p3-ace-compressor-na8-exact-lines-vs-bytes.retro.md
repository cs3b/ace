---
id: 8q62p3
title: ace-compressor-na8-exact-lines-vs-bytes
type: standard
tags: []
created_at: "2026-03-07 01:47:53"
status: active
task_ref: 8q5.t.na8
---

# ace-compressor-na8-exact-lines-vs-bytes

## What Went Well
- `8q5.t.na8` succeeded at its actual delivery goal: `ace-compressor` is now a runnable ACE tool with deterministic exact-mode output instead of a concept or research note.
- Exact mode now produces a normalized structured artifact that is substantially less verbose than the original `ContextPack/1` MVP shape, which de-risks later stable-ID and patch work.
- The current exact output is a meaningful agent-UX win on line count. On `docs/vision.md`, the artifact drops from `101` lines to `37`, which makes it easier to inspect within tools that reveal content in line-bounded chunks.
- The exact-mode work clarified the product split: preservation/normalization is a different job from aggressive compression, and we now have a concrete baseline to compare future modes against.

## What Could Be Improved
- The current result is still a partial miss against the original idea. On `docs/vision.md`, exact mode is `3,691 B` versus `3,663 B` original, so it does not yet deliver a byte win on a narrative-heavy source.
- We implicitly mixed three success metrics during `na8`: byte reduction, line reduction, and structured normalization. The task shipped the latter two more clearly than the first.
- The package name and early idea language can make users expect that exact mode itself should already be the smaller-bytes answer, when the current implementation is better understood as the safe normalized baseline.
- The original “lossless should be 30-40% smaller” expectation from the archived idea was too strong for narrative docs without a more aggressive, explicitly lossy compact mode.

## Key Learnings
- Exact mode should be positioned as the preserve/normalize mode, not the phase that proves the compressor concept on bytes.
- Line-count reduction is a real operational win for agents, but it should be treated as a secondary success metric, not proof that the original compression promise has been met.
- The original idea sequence still holds: lossless first, lossy second, advanced architecture after that. `na8` validated the first phase and clarified why `nah` needs to own the byte-win goal.
- Stable update architecture depends more on deterministic normalized structure than on raw byte savings, so `na8` still creates useful groundwork for `8q5.t.naj`.

## Action Items
- Keep `8q5.t.nah` as the next compression-focused phase, but tighten its charter so compact mode explicitly owns the byte-win promise. Its acceptance criteria should compare compact output against both raw source bytes and exact-mode bytes.
- Keep `8q5.t.nai` separate as ACE-native integration work. It should not assume exact mode has already “solved compression”; its job is to make source resolution and source-scope behavior feel native in ACE.
- Keep `8q5.t.naj` separate as update architecture work. It should build on exact mode as the normalized baseline for stable IDs, provenance, and patching rather than trying to solve byte reduction.
- Update future `ace-compressor` docs and task wording to say “exact mode preserves and normalizes; compact mode pursues materially smaller payloads” so users are not asked to infer that split from implementation details.
