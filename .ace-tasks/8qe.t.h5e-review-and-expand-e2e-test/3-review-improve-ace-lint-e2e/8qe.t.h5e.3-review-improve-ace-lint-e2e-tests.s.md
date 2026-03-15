---
id: 8qe.t.h5e.3
status: draft
priority: medium
created_at: "2026-03-15 11:26:10"
estimate: TBD
dependencies: []
tags: [e2e, testing, review]
parent: 8qe.t.h5e
bundle:
  presets: [project]
  files: [ace-lint/test/e2e]
---

# Review & improve ace-lint E2E tests

## Behavioral Specification

### User Experience
- **Input**: Existing E2E test suite for `ace-lint` (1 scenario, 7 test cases).
- **Process**: Run `/as-e2e-review` on the package to produce a coverage matrix. Analyze gaps and improvements. Apply changes. Verify tests pass.
- **Output**: Improved E2E test suite with better coverage, consistent patterns, and all tests passing.

### Expected Behavior

1. Run `/as-e2e-review` on `ace-lint` to produce a coverage matrix mapping CLI functionality to existing E2E test coverage.
2. Analyze the coverage matrix for: missing happy-path scenarios, missing error-path scenarios, inconsistent test patterns, flaky test indicators, and sandbox isolation gaps.
3. Apply improvements: add missing scenarios, fix inconsistencies, improve assertions, ensure proper sandbox setup/teardown.
4. Verify all E2E tests pass with `ace-test ace-lint`.

### Success Criteria

- [ ] Coverage matrix produced from `/as-e2e-review`
- [ ] Gaps identified and documented
- [ ] Improvements applied to E2E test files
- [ ] All E2E tests pass after changes
- [ ] No regressions in existing test coverage

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (review)
- **Slice Outcome**: `ace-lint` E2E tests reviewed, improved, and verified
- **Advisory Size**: small
- **Context Dependencies**: Existing E2E test files in `ace-lint/test/e2e/`

### Verification Plan

#### Integration / E2E Validation
- [ ] All E2E tests pass: `ace-test ace-lint`
- [ ] Coverage matrix shows no critical gaps remaining

#### Verification Commands
- [ ] `ace-test ace-lint`

## Objective

Review and improve the E2E test suite for `ace-lint`, ensuring comprehensive coverage with consistent patterns.

## Scope of Work

- Review existing 1 scenario and 7 test cases
- Produce coverage matrix via `/as-e2e-review`
- Apply improvements from the review
- Verify all tests pass

## Out of Scope

- No changing CLI command behavior
- No unit test or molecule test changes
- No new feature development

## References

- Parent: 8qe.t.h5e -- Review and expand E2E test coverage across ACE packages
- `/as-e2e-review` workflow
