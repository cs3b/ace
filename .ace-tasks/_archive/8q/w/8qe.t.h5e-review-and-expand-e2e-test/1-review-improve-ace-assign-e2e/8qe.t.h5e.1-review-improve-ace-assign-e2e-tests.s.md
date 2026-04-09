---
id: 8qe.t.h5e.1
status: done
priority: medium
created_at: "2026-03-15 11:26:09"
estimate: TBD
dependencies: []
tags: [e2e, testing, review]
parent: 8qe.t.h5e
bundle:
  presets: [project]
  files: [ace-assign/test-e2e/scenarios]
needs_review: false
---

# Review & improve ace-assign E2E tests

## Behavioral Specification

### User Experience
- **Input**: Existing E2E test suite for `ace-assign` (2 scenarios, 10 test cases).
- **Process**: Run the canonical E2E lifecycle for the package, preferably via `/as-e2e-manage`: produce a coverage matrix, generate a concrete change plan, apply the approved rewrite, then record package-scoped verification.
- **Output**: Improved E2E test suite with better coverage, consistent patterns, and all tests passing.

### Expected Behavior

1. Run `/as-e2e-manage` on `ace-assign` to run `review -> plan-changes -> rewrite`, producing a coverage matrix plus classified KEEP/MODIFY/REMOVE/CONSOLIDATE/ADD decisions.
2. Review the change plan for overlap, gaps, outdated assertions, consolidation opportunities, and any missing E2E decision evidence.
3. Execute the approved rewrite: update, remove, consolidate, or add TCs/scenarios as required by the plan, and keep scenario structure aligned with the canonical E2E authoring contract.
4. Record package-scoped verification for `ace-test ace-assign`.

### Success Criteria

- [x] Coverage matrix produced for `ace-assign`
- [x] Change plan documents KEEP / MODIFY / REMOVE / CONSOLIDATE / ADD decisions
- [x] Rewrite summary reflects the approved E2E changes
- [x] Package-scoped verification is recorded after the rewrite
- [x] No regressions in retained E2E coverage

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (review)
- **Slice Outcome**: `ace-assign` E2E tests managed through review, plan, rewrite, and package-scoped verification
- **Advisory Size**: small
- **Context Dependencies**: Existing E2E test files in `ace-assign/test-e2e/scenarios/`

### Verification Plan

#### Integration / E2E Validation
- [x] Package-scoped verification passes after rewrite: `ace-test ace-assign`
- [x] Coverage matrix and change plan are attached or summarized in the task output

#### Verification Commands
- [x] `ace-test ace-assign`

## Objective

Run the canonical E2E lifecycle for `ace-assign`, ensuring review findings, rewrite decisions, and package-scoped verification are all captured consistently.

## Scope of Work

- Run the canonical lifecycle against the existing E2E scenarios and test cases for `ace-assign`
- Produce a coverage matrix and classified change plan
- Execute the approved rewrite
- Record package-scoped verification

## Out of Scope

- No changing CLI command behavior
- No unit test or molecule test changes
- No new feature development

## References

- Parent: 8qe.t.h5e -- Review and expand E2E test coverage across ACE packages
- `/as-e2e-manage` workflow
- `/as-e2e-review`, `/as-e2e-plan-changes`, and `/as-e2e-rewrite` workflows
