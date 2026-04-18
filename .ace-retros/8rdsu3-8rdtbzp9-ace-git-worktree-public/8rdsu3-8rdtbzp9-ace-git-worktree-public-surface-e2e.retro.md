---
id: 8rdsu3
title: 8rd.t.bzp.9 ace-git-worktree public-surface e2e rewrite
type: standard
tags: [assignment, 8rd.t.bzp.9, ace-git-worktree, e2e, release]
created_at: "2026-04-14 19:13:26"
status: active
---

# 8rd.t.bzp.9 ace-git-worktree public-surface e2e rewrite

## What Went Well
- Rewrote the retained `ace-git-worktree` goal-based scenarios to explicit public command journeys and removed hidden "learned from Goal 1" dependencies.
- Added new goal-style coverage for config-surface validation and PR lifecycle, then iterated until `ace-test-e2e ace-git-worktree` reached 17/17 passing.
- Updated usage/getting-started docs to mirror the new public contracts (JSON output expectations, task filters, and remove-by-task with `--delete-branch`).
- Completed release flow for `ace-git-worktree v0.21.0` with clean package/root changelog updates and passing monorepo propagation proof (`TS-MONO-001`, classification `SAFE`).

## What Could Be Improved
- Task references to `.ace-local/e2e-migration/ace-git-worktree/{review,plan}.md` were missing in this workspace, forcing reliance on task spec text and in-repo test files.
- Several E2E failures were caused by artifact contract drift and list-output inconsistencies, which required multiple verifier/runnable expectation adjustments.
- Release workflow guidance referenced `--test-id`, but this environment expects positional `TEST_ID`; this mismatch should be normalized in docs/workflows.

## Action Items
- Add a small workflow note in release instructions clarifying `ace-test-e2e PACKAGE TEST_ID` positional syntax.
- Tighten E2E authoring guidance so required runner artifacts match verifier requirements exactly (including optional artifact conventions).
- Consider a follow-up stabilization pass on `ace-git-worktree list` post-create visibility to reduce tool-bug noise in task-aware scenarios.
