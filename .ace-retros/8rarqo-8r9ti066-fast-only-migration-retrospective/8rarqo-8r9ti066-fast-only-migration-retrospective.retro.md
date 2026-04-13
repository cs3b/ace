---
id: 8rarqo
title: 8r9.t.i06.6 fast-only migration retrospective
type: standard
tags: [8r9.t.i06.6, assignment, fastfeat]
created_at: "2026-04-11 18:29:38"
status: active
---

# 8r9.t.i06.6 fast-only migration retrospective

## What Went Well
- Completed the subtree drive loop end-to-end without manual stop conditions.
- Migrated `ace-hitl` deterministic coverage to `test/fast/commands/` and removed the legacy `test/commands/` path.
- Updated user-facing and demo documentation in the same implementation slice, preventing test-path drift.
- Verification remained fast and deterministic:
  - `ace-test ace-hitl`
  - `ace-test ace-hitl all`
  - `cd ace-hitl && ace-test all --profile 6`
  - All passed with 27 tests and 0 failures.
- Release execution stayed scoped to the intended package (`ace-hitl`) and produced `v0.8.2` with package + root changelog updates.

## What Could Be Improved
- The test-file move and old-file deletion landed across separate commits because path-scoped commit batching did not include the deleted path initially.
- Release auto-detection from `origin/main...HEAD` contains many historical branch changes; subtree-targeted package resolution should remain explicit to avoid accidental multi-package release scope.

## Action Items
- When moving files during scoped commits, include both new and old paths in the first commit command to avoid follow-up cleanup commits.
- Continue adding explicit fast-only testing contract sections to package docs during migrations to keep future release reviews straightforward.
- Keep pre-commit fallback behavior (`ace-lint`) documented in assignment reports when native `/review` is unavailable.
