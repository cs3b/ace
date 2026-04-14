---
id: 8rd.t.bzp.b
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-idea, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-idea/docs/usage.md, .ace-local/e2e-migration/ace-idea/review.md, .ace-local/e2e-migration/ace-idea/plan.md]
  commands: [ace-task show 8rd.t.bzp.b --content]
needs_review: false
---

# Rewrite ace-idea E2E suite to public-surface goal style

## Objective

Remove hidden ID-handling recipes from `ace-idea` lifecycle E2E and de-duplicate list assertions so the suite tracks real public behavior instead of artifact-mined flow.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-idea` E2E journeys from `ace-idea/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-idea/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 create-idea - Strong E2E value: real CLI subprocess + persisted artifact/frontmatter; clear user-facing path.
3. Rewrite or narrow brittle coverage identified by the plan: TC-003 move-idea - Remove hidden recipe: derive/reuse ID via public command output flow; keep impact-first filesystem assertions; TC-004 archive-idea - Same as TC-003: remove internal-artifact dependency and keep archive-state oracle.
4. Add any new goal-style scenarios or test cases required by the plan: none required in this migration pass - n/a.
5. Apply the package's public-surface gap actions before treating the suite as complete: Rewrite runner instructions for TC-003/004 so command sequencing is anchored in documented public usage (`create` output -> `update` with visible ID) and not artifact-mining recipes.; Ensure each TC objective is executable using docs/help/CLI alone; any required preconditions should be expressed as visible scenario setup, not hidden operational steps.; Add lightweight freshness metadata process (e.g., `last-verified`) in scenario maintenance workflow..
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-idea/docs/usage.md` remain the source of truth for the retained `ace-idea` workflows.
- `ace-test-e2e ace-idea ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-idea` is in scope only when `.ace-local/e2e-migration/ace-idea/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Idea move/archive flows are executable from docs/help/CLI alone.
- Duplicate list assertions are reduced.
- The package no longer depends on hidden ID-mining recipes in E2E.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-idea` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-idea/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Eliminate hidden-recipe-driven ID handling in TC-003/004 runner instructions.; De-duplicate list assertions across TC-002/003/004.; Add maintenance metadata and explicit oracle-strength checks to reduce stale scenario drift.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-idea/review.md` and `.ace-local/e2e-migration/ace-idea/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-idea ...` reruns for the rewritten lifecycle scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.12-run-ace-idea.r.md`
- `.ace-local/e2e-migration/ace-idea/review.md`
- `.ace-local/e2e-migration/ace-idea/plan.md`
