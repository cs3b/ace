---
id: 8rd.t.bzp.9
status: pending
priority: medium
created_at: "2026-04-14 08:00:13"
estimate: TBD
dependencies: []
tags: [ace-git-worktree, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-git-worktree/docs/usage.md, .ace-local/e2e-migration/ace-git-worktree/review.md, .ace-local/e2e-migration/ace-git-worktree/plan.md]
  commands: [ace-task show 8rd.t.bzp.9 --content]
needs_review: false
---

# Rewrite ace-git-worktree E2E suite to public-surface goal style

## Objective

Rewrite `ace-git-worktree` toward explicit self-contained public journeys, remove internal-detail assertions, and rebalance the suite around real lifecycle value.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-git-worktree` E2E journeys from `ace-git-worktree/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-git-worktree/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TS-WORKTREE-001/TC-004 - Valid public-surface dry-run user job with strong no-op oracle; TS-WORKTREE-001/TC-005 - Real remove lifecycle impact and clear final-state verification; TS-WORKTREE-002/TC-003 - Useful user-facing task filtering behavior.
3. Rewrite or narrow brittle coverage identified by the plan: TS-WORKTREE-001/TC-002 - Replace “learned from Goal 1” with explicit command sequence from docs/help; preserve baseline-before/after list and FS checks; TS-WORKTREE-001/TC-003 - Keep `switch` job, narrow list-format checks to parseability/usable output; avoid redundant style-level assertions; TS-WORKTREE-001/TC-006 - Keep prune scenario but reduce manual orchestration burden; verify final git metadata + FS clean as primary oracle.
4. Add any new goal-style scenarios or test cases required by the plan: `TC: create-pr-worktree-lifecycle` - task-aware/lifecycle scenario; `TC: config-surface-validation` - basic-lifecycle scenario.
5. Apply the package's public-surface gap actions before treating the suite as complete: Publish minimal JSON output contract for `list --format json`; Add explicit docs examples for `--no-task-associated` and remove-by-task with `--delete-branch`; Add one goal-style example per retained scenario in docs/getting-started.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-git-worktree/docs/usage.md` remain the source of truth for the retained `ace-git-worktree` workflows.
- `ace-test-e2e ace-git-worktree ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-git-worktree` is in scope only when `.ace-local/e2e-migration/ace-git-worktree/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Unsupported internal-detail checks are gone from retained E2E.
- Task-aware flows stay covered through real public lifecycle outcomes.
- The package plan's remove/consolidate/add decisions are fully reflected.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-git-worktree` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-git-worktree/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Convert runner prompts from sequence-coupled recipes to explicit public command journeys (docs/help/CLI only).; Remove unsupported internal-detail checks (`.ace-tasks`, undocumented JSON field schema) from verifier contracts.; Consolidate duplicated discovery/multi-task checks and rebalance E2E toward real lifecycle outcomes over formatting/detail overlap.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-git-worktree/review.md` and `.ace-local/e2e-migration/ace-git-worktree/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-git-worktree ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.10-run-ace-git-worktree.r.md`
- `.ace-local/e2e-migration/ace-git-worktree/review.md`
- `.ace-local/e2e-migration/ace-git-worktree/plan.md`
