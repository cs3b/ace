---
id: 8rd.t.bzp.g
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-overseer, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-overseer/docs/usage.md, .ace-local/e2e-migration/ace-overseer/review.md, .ace-local/e2e-migration/ace-overseer/plan.md]
  commands: [ace-task show 8rd.t.bzp.g --content]
needs_review: false
---

# Rewrite ace-overseer E2E suite to public-surface goal style

## Objective

Keep the orchestration value in `ace-overseer` E2E while removing hidden procedure details from override and prune flows and adding the missing high-value public journeys.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-overseer` E2E journeys from `ace-overseer/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-overseer/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-002 work-on - Core E2E value: validates real worktree + tmux + assignment orchestration with strong final-state oracle.; TC-005 prune-workflow - Core E2E value: validates real safe-prune lifecycle and final-state effects..
3. Rewrite or narrow brittle coverage identified by the plan: TC-003 idempotent-rerun - Remove naming-convention dependence (`t.q7w`) and verify idempotency through public status/worktree state only.; TC-004 preset-override - Replace hidden-recipe evidence paths with public-surface oracle: explicit command outputs and stable assignment-status indicators.; TC-005 prune-workflow - Simplify into public flow; keep normal prune lifecycle oracle, reduce low-level choreography and debug-capture burden..
4. Add any new goal-style scenarios or test cases required by the plan: `TC-status-watch-refresh` - `TS-OVERSEER-002-status-and-ops`; `TC-work-on-multi-task-bundle` - `TS-OVERSEER-002-status-and-ops`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify docs for preset override verification path and expected observable outputs; Document recommended idempotency verification oracle for rerun; Document prune lifecycle minimal flow with user-facing commands only.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-overseer/docs/usage.md` remain the source of truth for the retained `ace-overseer` workflows.
- `ace-test-e2e ace-overseer ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-overseer` is in scope only when `.ace-local/e2e-migration/ace-overseer/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Override and prune behavior are validated without hidden evidence gathering.
- Missing high-value orchestration flows are covered.
- The final scenario set matches the plan's keep/modify/remove/add split.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-overseer` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-overseer/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-004 preset override to eliminate hidden-recipe evidence gathering and use only public CLI/doc-surfaced behavior.; Simplify TC-005 prune workflow to shortest public command sequence with final sandbox-state oracle.; Remove standalone TC-001 survey and absorb minimal help check into functional flow preflight.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-overseer/review.md` and `.ace-local/e2e-migration/ace-overseer/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-overseer ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.17-run-ace-overseer.r.md`
- `.ace-local/e2e-migration/ace-overseer/review.md`
- `.ace-local/e2e-migration/ace-overseer/plan.md`
