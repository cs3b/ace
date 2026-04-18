---
id: 8rd.t.bzp.j
status: done
priority: medium
created_at: "2026-04-14 08:00:14"
estimate: TBD
dependencies: []
tags: [ace-review, e2e, migration]
parent: 8rd.t.bzp
bundle:
  presets: [project]
  files: [ace-review/docs/usage.md, .ace-local/e2e-migration/ace-review/review.md, .ace-local/e2e-migration/ace-review/plan.md]
  commands: [ace-task show 8rd.t.bzp.j --content]
needs_review: false
---

# Rewrite ace-review E2E suite to public-surface goal style

## Objective

Rewrite `ace-review` so it proves a real user can run the tool from docs/help and get meaningful review artifacts, without treating provider blockers as success.

## Behavioral Specification

### User Experience

- A package maintainer can execute the retained `ace-review` E2E journeys from `ace-review/docs/usage.md` and `--help` without hidden recipes.
- The rewritten suite proves the public CLI path and the final user-visible outcome, using filesystem end state or real product output as the primary oracle.
- Any docs/help updates stay in scope only when the migration plan says the retained workflow is not yet self-serve from the documented public path.

### Expected Behavior

1. Implement the package migration plan from `.ace-local/e2e-migration/ace-review/plan.md` rather than inventing new scenario scope.
2. Preserve the retained high-value journeys identified in the plan: Keep scenario family `TS-REVIEW-001-review-workflow` as the base real-execution track..
3. Rewrite or narrow brittle coverage identified by the plan: `TC-001-single-model` - MODIFY; `TC-002-multi-model` - MODIFY.
4. Add any new goal-style scenarios or test cases required by the plan: `TC-003-docs-path-onboarding` - `TS-REVIEW-001` or new `TS-REVIEW-002`.
5. Apply the package's public-surface gap actions before treating the suite as complete: Align runner instructions with documented CLI usage patterns and remove fixture-specific naming assumptions from TC goals.; Ensure verifier pass criteria prioritize final product output quality (review/session artifacts with expected structure) over mere process termination.; Document provider prerequisite handling as explicit precondition/error path, not a passing substitute for successful tool output..
6. Use final sandbox state or real product output as the primary oracle, with runner observations only as secondary evidence.

### Interface Contract

- Public package CLI commands and `ace-review/docs/usage.md` remain the source of truth for the retained `ace-review` workflows.
- `ace-test-e2e ace-review ...` is the verification entrypoint for the rewritten E2E journeys.
- `ace-test ace-review` is in scope only when `.ace-local/e2e-migration/ace-review/plan.md` explicitly calls for fast/feat backfill after E2E overlap reduction.
- The rewrite must not make non-`ace-*` probing, hidden fixture plumbing, or helper-artifact-first verdicts the main contract.

## Success Criteria

- A successful `ace-review` run produces meaningful review/session output under the verifier's stricter contract.
- Provider blockers are reported as failures, not success-equivalents.
- The suite includes one explicit docs-path proof of user-doable execution.

## Vertical Slice Decomposition

- Slice type: standalone package rewrite
- Slice outcome: `ace-review` has a public-surface goal-style E2E suite that matches `.ace-local/e2e-migration/ace-review/plan.md`
- Advisory size: medium
- Execution order inside the slice follows the plan priorities: Tighten verifier PASS criteria so provider-unavailable outcomes are actionable failures, not success-equivalents.; Remove hidden-recipe dependencies from runner goals (fixture-specific preset shortcuts, internal-only setup assumptions).; Add one explicit docs-path TC that proves user-doable execution from public documentation and CLI help.

## Validation Questions

- None. `.ace-local/e2e-migration/ace-review/review.md` and `.ace-local/e2e-migration/ace-review/plan.md` provide sufficient package-specific direction for implementation.

## Verification Plan

- Run targeted `ace-test-e2e ace-review --scenario TS-REVIEW-001-review-workflow`.

## References

- `.ace-local/assign/8rczn4/reports/010.20-run-ace-review.r.md`
- `.ace-local/e2e-migration/ace-review/review.md`
- `.ace-local/e2e-migration/ace-review/plan.md`
