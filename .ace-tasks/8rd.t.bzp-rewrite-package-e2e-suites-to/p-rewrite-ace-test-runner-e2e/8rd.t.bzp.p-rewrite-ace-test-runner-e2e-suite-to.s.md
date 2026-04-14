---
id: 8rd.t.bzp.p
status: pending
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-test-runner, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-test-runner/docs/usage.md, .ace-local/e2e-migration/ace-test-runner/review.md, .ace-local/e2e-migration/ace-test-runner/plan.md]
  commands: [ace-task show 8rd.t.bzp.p --content]
needs_review: false
---

# Rewrite ace-test-runner E2E suite to public-surface goal style

## Objective

Reduce duplication and workaround-driven execution in `ace-test-runner` E2E while keeping the real package-target and suite-target orchestration value.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-test-runner` E2E journeys from `ace-test-runner/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-test-runner/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TS-TEST-001 / TC-002 run-specific-file - Keep as focused public CLI file-path journey (`PACKAGE + file`) with clear user value.; TS-TEST-002 / TC-002 verify-failure-propagation - Keep as core suite non-zero propagation validation that unit tests cannot fully replace..
3. Rewrite or narrow brittle coverage identified by the plan: TS-TEST-001 / TC-001 run-package-tests - Re-scope to canonical “package + target” happy path and add stronger end-state oracle (result artifacts + summary consistency) without duplicating TC-002 assertions.; TS-TEST-002 / TC-001 run-full-suite - Remove `.monorepo-root` recipe and preferred/fallback command branching; use single documented invocation path and assert suite-level aggregate outcome directly..
4. Add any new goal-style scenarios or test cases required by the plan: suite-target-pass-through - TS-TEST-002-suite-execution.
5. Apply the package's public-surface gap actions before treating the suite as complete: Document one canonical E2E invocation path for suite scenario; Add explicit docs note for E2E-friendly suite invocation constraints.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-test-runner/docs/usage.md` remain the source of truth for the retained `ace-test-runner` workflows.
- `ace-test-e2e ace-test-runner ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-test-runner` is in scope only when `.ace-local/e2e-migration/ace-test-runner/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Duplicate and workaround-driven `ace-test-runner` E2E coverage is removed.
- One canonical public path exists for the retained suite execution scenario.
- The user-visible suite-target flow is covered end to end.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-test-runner` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-test-runner/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Remove workaround-driven execution from TS-TEST-002 TC-001 and enforce one public-surface command path.; Consolidate TS-TEST-001 TC-001/TC-003 into a single non-duplicative package-target journey.; Add suite `--target` pass-through E2E coverage for a user-visible orchestration path currently missing.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-test-runner/review.md` and `.ace-local/e2e-migration/ace-test-runner/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-test-runner ...` reruns for the rewritten scenarios.

## References

- `.ace-local/assign/8rczn4/reports/010.26-run-ace-test-runner.r.md`
- `.ace-local/e2e-migration/ace-test-runner/review.md`
- `.ace-local/e2e-migration/ace-test-runner/plan.md`
