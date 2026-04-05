---
id: 8r0wpg
title: 8r0-t-orn-3-smart-worktree-hitl-scope-resolution
type: standard
tags: [ace-hitl, assign, worktree]
created_at: "2026-04-01 21:48:18"
status: active
---

# 8r0-t-orn-3-smart-worktree-hitl-scope-resolution

## What Went Well
- Scope behavior was implemented at the organism/molecule boundary (`HitlManager` + `WorktreeScopeResolver`) without widening write-path semantics for `create`/`update`.
- CLI contract changes were validated end-to-end with expanded command-level tests covering default scope, explicit scope, fallback behavior, ambiguity failures, and resolved-location output.
- Release execution stayed scoped to the affected package (`ace-hitl`) and produced a clean version/changelog bump (`0.3.0` -> `0.4.0`) with root changelog alignment.

## What Could Be Improved
- Existing test helper patterns assumed `manager.show` returned a model, which caused one avoidable failure after return-shape expansion to include resolution metadata.
- Scope detection logic currently relies on Git command outputs; a dedicated lower-level unit test file for `WorktreeScopeResolver` would reduce future refactor risk.
- Pre-commit review fallback (`ace-lint`) surfaced unrelated task-spec warnings; tighter changed-file scoping for subtree-owned files would reduce review noise.

## Key Learnings
- For worktree-aware CLI features, injecting a test resolver (`StaticScopeResolver`) is a practical way to test behavior deterministically without real git worktree setup.
- Returning structured resolution metadata from manager methods enables output contract expansion (like explicit resolved location) without duplicating lookup logic in CLI commands.
- In assignment-driven flows, committing task-spec checkbox/status updates together with implementation context reduces drift between code state and task acceptance state.

## Action Items
- **Continue**: keep read-path scope logic centralized in manager/molecule layers and keep CLI classes focused on argument validation + rendering.
- **Start**: add dedicated molecule tests for `WorktreeScopeResolver` in a follow-up hardening slice.
- **Start**: add a small helper in pre-commit-review workflow to filter lint scope to subtree-owned modified files when available.
- **Stop**: relying on implicit assumptions in command tests when manager return types evolve; assert against explicit keys where structured payloads are expected.
