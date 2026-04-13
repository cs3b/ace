# E2E Plan Changes - ace-review

Reviewed package: `ace-review`
Scope: `TS-REVIEW-001-review-workflow`
Workflow: `ace-bundle wfi://e2e/plan-changes`

## Classification

- `REMOVE`: `TC-001-help-survey`
- `REMOVE`: `TC-002-preset-discovery`
- `REMOVE`: `TC-003-preset-composition`
- `REMOVE`: `TC-004-subject-processing`
- `REMOVE`: `TC-005-error-handling`
- `MODIFY`: `TC-006-single-model` -> `TC-001-single-model`
- `MODIFY`: `TC-007-multi-model` -> `TC-002-multi-model`
- `ADD`: `e2e-decision-record.md` documenting review/plan outcomes
- `CONSOLIDATE`: none

## Rewrite Actions

1. Replace seven-goal runner/verifier bundles with two-goal execution bundles.
2. Remove old TC files and create renamed retained pair:
   - `TC-001-single-model` (real single-model run)
   - `TC-002-multi-model` (real multi/reviewers runs)
3. Update `scenario.yml` metadata:
   - scenario title/cost tags aligned to execution workflows
   - `sandbox-layout` reduced to two result sets
   - `unit-coverage-reviewed` refreshed to `test/fast` and `test/feat` paths
4. Add deterministic migration references in decision record and package docs.
