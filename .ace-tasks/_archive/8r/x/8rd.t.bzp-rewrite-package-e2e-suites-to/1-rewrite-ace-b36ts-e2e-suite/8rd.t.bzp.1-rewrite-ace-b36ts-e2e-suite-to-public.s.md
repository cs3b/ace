---
id: 8rd.t.bzp.1
status: done
priority: medium
created_at: "2026-04-14 08:00:11"
estimate: TBD
dependencies: []
tags: [ace-b36ts, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-b36ts/docs/usage.md, .ace-local/e2e-migration/ace-b36ts/review.md, .ace-local/e2e-migration/ace-b36ts/plan.md]
  commands: [ace-task show 8rd.t.bzp.1 --content]
needs_review: false
---

# Rewrite ace-b36ts E2E suite to public-surface goal style

## Objective

Repair the current `ace-b36ts` scenario contract drift and expand coverage from one encode flow into the higher-value decode and split/json public workflows.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-b36ts` E2E journeys from `ace-b36ts/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-b36ts/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: None unchanged as-is. Existing TC has value but needs contract and oracle corrections..
3. Rewrite or narrow brittle coverage identified by the plan: `TS-B36TS-001 / TC-001-notes-reorganization` - MODIFY.
4. Add any new goal-style scenarios or test cases required by the plan: `TC-002 decode-roundtrip-from-real-token` - `TS-B36TS-001`; `TC-003 split-and-json-output-for-archive-pathing` - `TS-B36TS-001`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify migration-era E2E authoring contract (scenario/case canonical fields, oracle ordering, no hidden recipes); Add explicit docs/help linkage in TC prompts.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-b36ts/docs/usage.md` remain the source of truth for the retained `ace-b36ts` workflows.
- `ace-test-e2e ace-b36ts ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-b36ts` is in scope only when `.ace-local/e2e-migration/ace-b36ts/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The retained notes-reorganization case no longer has conflicting artifact expectations.
- Decode and split/json user jobs are represented in goal-style E2E.
- Scenario structure and guidance no longer drift away from the current handbook contract.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-b36ts` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-b36ts/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Repair runner/verifier/scenario contract drift so the primary oracle is unambiguous and executable.; Expand from single encode-day TC to include decode and split/json public-surface jobs.; Add explicit evidence metadata (`e2e-justification`, `unit-coverage-reviewed`, oracle declaration) to prevent hidden-recipe regressions.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-b36ts/review.md` and `.ace-local/e2e-migration/ace-b36ts/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-b36ts ...` reruns for the modified and added TCs.

## References

- `.ace-local/assign/8rczn4/reports/010.02-run-ace-b36ts.r.md`
- `.ace-local/e2e-migration/ace-b36ts/review.md`
- `.ace-local/e2e-migration/ace-b36ts/plan.md`
