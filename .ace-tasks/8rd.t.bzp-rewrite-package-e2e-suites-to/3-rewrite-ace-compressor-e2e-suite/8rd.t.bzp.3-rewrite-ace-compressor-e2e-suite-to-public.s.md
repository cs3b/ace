---
id: 8rd.t.bzp.3
status: pending
priority: medium
created_at: "2026-04-14 08:00:11"
estimate: TBD
dependencies: []
tags: [ace-compressor, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-compressor/docs/usage.md, .ace-local/e2e-migration/ace-compressor/review.md, .ace-local/e2e-migration/ace-compressor/plan.md]
  commands: [ace-task show 8rd.t.bzp.3 --content]
needs_review: false
---

# Rewrite ace-compressor E2E suite to public-surface goal style

## Objective

Keep the strong `ace-compressor` smoke flows, rewrite the brittle refusal path, and add the missing documented `--mode agent` and `benchmark` workflows.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-compressor` E2E journeys from `ace-compressor/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-compressor/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help surface - Keep as low-friction command-surface smoke; validates packaged binary wiring and operator-visible options.; TC-003 per-source output directory - Keep as high-value filesystem-first oracle for real output path emission and ordering guarantees..
3. Rewrite or narrow brittle coverage identified by the plan: TC-002 exact stdio and stats smoke - Narrow assertions to integration-visible contracts and reduce redundant token-level checks already covered heavily by unit tests; preserve checks for mode/reporting/output path semantics.; TC-004 compact refusal contract - Replace verbatim fixture recipe with behavior-driven rule-heavy fixture shape; keep refusal/guidance contract checks but remove brittle text dependency and strengthen public-surface realism..
4. Add any new goal-style scenarios or test cases required by the plan: TC-005 agent-mode smoke - `TS-COMP-001-cli-smoke`; TC-006 benchmark smoke - `TS-COMP-001-cli-smoke`.
5. Apply the package's public-surface gap actions before treating the suite as complete.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-compressor/docs/usage.md` remain the source of truth for the retained `ace-compressor` workflows.
- `ace-test-e2e ace-compressor ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-compressor` is in scope only when `.ace-local/e2e-migration/ace-compressor/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- Refusal semantics are still covered without fixture-prescriptive runner behavior.
- `--mode agent` and `benchmark` are represented as real user-facing E2E jobs.
- Existing strong filesystem-first oracles are preserved where appropriate.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-compressor` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-compressor/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: **TC-004 rewrite** to remove hidden recipe behavior and retain refusal semantics on public-surface terms.; **Add TC-005 agent smoke** to cover major documented mode gap.; **Add TC-006 benchmark smoke** to cover second major public-surface gap.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-compressor/review.md` and `.ace-local/e2e-migration/ace-compressor/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-compressor ...` reruns for the modified and new TCs.

## References

- `.ace-local/assign/8rczn4/reports/010.04-run-ace-compressor.r.md`
- `.ace-local/e2e-migration/ace-compressor/review.md`
- `.ace-local/e2e-migration/ace-compressor/plan.md`
