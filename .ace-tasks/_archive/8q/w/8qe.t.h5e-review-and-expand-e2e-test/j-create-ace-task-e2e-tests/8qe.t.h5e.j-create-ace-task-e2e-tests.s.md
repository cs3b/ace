---
id: 8qe.t.h5e.j
status: done
priority: medium
created_at: "2026-03-15 11:26:31"
estimate: TBD
dependencies: []
tags: [e2e, testing, create]
parent: 8qe.t.h5e
bundle:
  presets: [project]
  files: [ace-task]
needs_review: false
---

# Create ace-task E2E tests

## Behavioral Specification

### User Experience
- **Input**: Package `ace-task` with CLI entrypoints but no existing E2E test coverage.
- **Process**: Run `/as-e2e-create` to add 1-2 value-gated smoke scenarios for the package. For each candidate TC, review unit-test coverage first, keep only behavior that requires real CLI/filesystem/subprocess execution, record an E2E Decision Record, then record package-scoped verification.
- **Output**: New E2E smoke coverage that follows project conventions and is justified by the E2E Value Gate.

### Expected Behavior

1. Run `/as-e2e-create` on `ace-task` to scaffold the initial scenario structure for the chosen area code and context.
2. Define 1-2 smoke scenarios with 2-5 TCs each, keeping only TCs that pass the E2E Value Gate and explicitly documenting candidate behaviors that remain unit-only.
3. Produce an E2E Decision Record listing each candidate TC, the decision (ADD or SKIP), the E2E-only reason, and the unit tests reviewed.
4. Ensure proper sandbox setup/teardown for test isolation and record package-scoped verification with `ace-test ace-task`.

### Success Criteria

- [ ] E2E test directory structure created in `ace-task/test-e2e/scenarios/`
- [ ] 1-2 value-gated smoke scenarios are created with 2-5 TCs each
- [ ] E2E Decision Record documents ADD/SKIP decisions and unit-test evidence
- [ ] Tests use proper sandbox isolation
- [ ] Package-scoped verification is recorded
- [ ] Test patterns are consistent with existing E2E tests in other packages

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (create)
- **Slice Outcome**: `ace-task` has initial value-gated E2E smoke coverage with documented scenario boundaries
- **Advisory Size**: small
- **Context Dependencies**: `ace-task` CLI command implementations, existing E2E test patterns in other packages

### Verification Plan

#### Integration / E2E Validation
- [ ] Package-scoped verification passes: `ace-test ace-task`
- [ ] Scenario objectives and unit-coverage-reviewed fields reflect genuine E2E-only behavior

#### Verification Commands
- [ ] `ace-test ace-task`

## Objective

Create initial E2E smoke coverage for `ace-task`, adding only scenarios whose behavior requires real CLI/filesystem/subprocess execution.

## Scope of Work

- Scaffold E2E test structure via `/as-e2e-create`
- Select an area code and context for 1-2 value-gated smoke scenarios
- Record an E2E Decision Record with unit-test evidence for each candidate TC
- Ensure sandbox isolation and canonical test conventions
- Record package-scoped verification

## Out of Scope

- ❌ Changing CLI command behavior
- ❌ Unit test or molecule test changes
- ❌ Blanket per-command happy-path coverage when the E2E Value Gate does not justify it

## References

- Parent: 8qe.t.h5e — Review and expand E2E test coverage across ACE packages
- `/as-e2e-create` workflow
- E2E Value Gate and Decision Record requirements from the canonical create workflow
