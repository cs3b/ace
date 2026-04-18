---
id: 8rd.t.bzp.o
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-task, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-task/docs/usage.md, .ace-local/e2e-migration/ace-task/review.md, .ace-local/e2e-migration/ace-task/plan.md]
  commands: [ace-task show 8rd.t.bzp.o --content]
needs_review: false
---

# Rewrite ace-task E2E suite to public-surface goal style

## Objective

Keep the strong core lifecycle value in `ace-task`, make ref handoff deterministic, and add the missing `status` and `plan` public journeys.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-task` E2E journeys from `ace-task/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-task/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: `TS-TASK-001/TC-001 help survey` - Valid public-surface smoke for command discoverability and help wiring.; `TS-TASK-001/TC-004 doctor health/error split` - High E2E value; validates real CLI behavior against real broken-state transitions..
3. Rewrite or narrow brittle coverage identified by the plan: `TS-TASK-001/TC-002 create/show/list lifecycle` - Keep objective but reduce cross-TC coupling: resolve and persist selected ref within the TC artifact set, and keep goal self-sufficient for reruns.; `TS-TASK-001/TC-003 update/archive movement` - Narrow setup dependency on prior captures; prefer explicit prerequisite handoff contract from TC-002 output structure or deterministic fallback path documented in scenario..
4. Add any new goal-style scenarios or test cases required by the plan: `status-dashboard-real-state` - `TS-TASK-002-aux-cli-journeys`; `plan-path-cache-refresh` - `TS-TASK-002-aux-cli-journeys`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Add explicit docs note for E2E-safe `plan` validation path (prefer path output over inline content); Add short usage examples for `github-sync` preconditions in docs/help.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-task/docs/usage.md` remain the source of truth for the retained `ace-task` workflows.
- `ace-test-e2e ace-task ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-task` is in scope only when `.ace-local/e2e-migration/ace-task/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The retained core lifecycle scenario stays strong and less brittle across reruns.
- `status` and `plan` gain explicit E2E coverage.
- No hidden provider tricks or workaround-driven behavior are introduced.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-task` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-task/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Refactor TC-002 and TC-003 runner contracts to reduce brittle cross-goal reference resolution and make reruns deterministic.; Add new `status` E2E journey because this command has runtime behavior not currently validated beyond help discovery.; Add `plan` E2E journey focused on cache/path behavior (no hidden provider tricks), aligned with public docs/help guidance.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-task/review.md` and `.ace-local/e2e-migration/ace-task/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-task ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.25-run-ace-task.r.md`
- `.ace-local/e2e-migration/ace-task/review.md`
- `.ace-local/e2e-migration/ace-task/plan.md`
