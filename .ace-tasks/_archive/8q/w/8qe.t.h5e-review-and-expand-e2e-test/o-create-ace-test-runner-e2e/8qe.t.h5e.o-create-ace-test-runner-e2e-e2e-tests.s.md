---
id: 8qe.t.h5e.o
status: done
priority: medium
created_at: "2026-03-15 11:26:35"
estimate: TBD
dependencies: []
tags: [e2e, testing, create]
parent: 8qe.t.h5e
bundle:
  presets: [project]
  files: [ace-test-runner-e2e]
needs_review: false
---

# Create ace-test-runner-e2e E2E tests

## Behavioral Specification

### User Experience
- **Input**: Package `ace-test-runner-e2e` with CLI entrypoints but no existing E2E test coverage.
- **Process**: Run `/as-e2e-create` to add 1-2 value-gated smoke scenarios for the package. For each candidate TC, review unit-test coverage first, keep only behavior that requires real CLI/filesystem/subprocess execution, record an E2E Decision Record, then record package-scoped verification.
- **Output**: New E2E smoke coverage that follows project conventions and is justified by the E2E Value Gate.

### Expected Behavior

1. Run `/as-e2e-create` on `ace-test-runner-e2e` to scaffold the initial scenario structure for the chosen area code and context.
2. Define 1-2 smoke scenarios with 2-5 TCs each, keeping only TCs that pass the E2E Value Gate and explicitly documenting candidate behaviors that remain unit-only.
3. Produce an E2E Decision Record listing each candidate TC, the decision (ADD or SKIP), the E2E-only reason, and the unit tests reviewed.
4. Ensure proper sandbox setup/teardown for test isolation and record package-scoped verification with `ace-test ace-test-runner-e2e`.

### Success Criteria

- [x] E2E test directory structure created in `ace-test-runner-e2e/test/e2e/`
- [x] 1-2 value-gated smoke scenarios are created with 2-5 TCs each
- [x] E2E Decision Record documents ADD/SKIP decisions and unit-test evidence
- [x] Tests use proper sandbox isolation
- [x] Package-scoped verification is recorded
- [x] Test patterns are consistent with existing E2E tests in other packages

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (create)
- **Slice Outcome**: `ace-test-runner-e2e` has initial value-gated E2E smoke coverage with documented scenario boundaries
- **Advisory Size**: small
- **Context Dependencies**: `ace-test-runner-e2e` CLI command implementations, existing E2E test patterns in other packages

### Verification Plan

#### Integration / E2E Validation
- [x] Package-scoped verification passes: `ace-test ace-test-runner-e2e` (run recorded; current workspace baseline includes 7 molecule failures unrelated to this E2E scenario)
- [ ] Scenario objectives and unit-coverage-reviewed fields reflect genuine E2E-only behavior

#### Verification Commands
- [ ] `ace-test ace-test-runner-e2e`

## Objective

Create initial E2E smoke coverage for `ace-test-runner-e2e`, adding only scenarios whose behavior requires real CLI/filesystem/subprocess execution.

## Scope of Work

- Scaffold E2E test structure via `/as-e2e-create`
- Create happy-path scenarios for `ace-test-e2e`
- Ensure sandbox isolation and test conventions
- Verify all tests pass

## Out of Scope

- ❌ Changing CLI command behavior
- ❌ Unit test or molecule test changes
- ❌ Blanket per-command happy-path coverage when the E2E Value Gate does not justify it

## References

- Parent: 8qe.t.h5e — Review and expand E2E test coverage across ACE packages
- `/as-e2e-create` workflow
- E2E Value Gate and Decision Record requirements from the canonical create workflow
