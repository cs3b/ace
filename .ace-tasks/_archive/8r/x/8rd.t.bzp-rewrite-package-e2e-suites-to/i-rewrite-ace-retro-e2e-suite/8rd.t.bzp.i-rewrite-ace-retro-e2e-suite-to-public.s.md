---
id: 8rd.t.bzp.i
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-retro, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-retro/docs/usage.md, .ace-local/e2e-migration/ace-retro/review.md, .ace-local/e2e-migration/ace-retro/plan.md]
  commands: [ace-task show 8rd.t.bzp.i --content]
needs_review: false
---

# Rewrite ace-retro E2E suite to public-surface goal style

## Objective

Keep the healthy `ace-retro` smoke coverage while rewriting the remaining failure-transition case to reduce recipe coupling and preserve value.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-retro` E2E journeys from `ace-retro/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-retro/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: TC-001 help and usage surface - Retains executable-path `--help`/argument contract coverage as lightweight smoke.; TC-002 create/list/show lifecycle - Retains real persisted-state journey across separate CLI invocations with strong state oracle.; TC-003 folder and filter views - Retains real `_archive` routing + filter behavior on filesystem-backed data..
3. Rewrite or narrow brittle coverage identified by the plan: TC-004 doctor health to failure transition - Keep objective but reduce hidden recipe pressure: assert failure transition from user-observable corruption setup instructions, tighten verifier to state impact first, and avoid overfitting to a specific malformed-YAML string..
4. Add any new goal-style scenarios or test cases required by the plan: None in this pass..
5. Apply the package's public-surface gap actions before treating the suite as complete: Clarify negative-path guidance for doctor E2E in scenario docs; Keep usage/help parity checks explicit.
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-retro/docs/usage.md` remain the source of truth for the retained `ace-retro` workflows.
- `ace-test-e2e ace-retro ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-retro` is in scope only when `.ace-local/e2e-migration/ace-retro/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- The failure-transition path remains covered with lower runner friction.
- Retained TCs remain goal-style and end-state-first.
- No unnecessary scenario expansion is introduced.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-retro` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-retro/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Rewrite TC-004 runner/verifier pair to keep failure-transition value while lowering recipe coupling and friction.; Strengthen verifier ordering language in TC-001 and TC-004 so final sandbox/product state remains the first oracle.; Keep TS-RETRO-001 as a focused smoke scenario and avoid expanding into matrix-style filter permutations already covered by fast tests.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-retro/review.md` and `.ace-local/e2e-migration/ace-retro/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-retro ...` reruns for the retained scenario.

## References

- `.ace-local/assign/8rczn4/reports/010.19-run-ace-retro.r.md`
- `.ace-local/e2e-migration/ace-retro/review.md`
- `.ace-local/e2e-migration/ace-retro/plan.md`
