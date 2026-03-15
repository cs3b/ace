---
id: 8qe.t.h5e.l
status: draft
priority: medium
created_at: "2026-03-15 11:26:32"
estimate: TBD
dependencies: []
tags: [e2e, testing, create]
parent: 8qe.t.h5e
bundle:
  presets: [project]
  files: [ace-demo]
---

# Create ace-demo E2E tests

## Behavioral Specification

### User Experience
- **Input**: Package `ace-demo` with CLI command(s) (`ace-demo` with 6 commands) but no existing E2E test coverage.
- **Process**: Run `/as-e2e-create` on the package to scaffold E2E test structure. Create supplementary happy-path scenarios covering core CLI functionality. Verify tests pass.
- **Output**: New E2E test suite with happy-path coverage for all CLI commands, following project E2E test conventions.

### Expected Behavior

1. Run `/as-e2e-create` on `ace-demo` to scaffold the E2E test directory structure and base scenario file.
2. Create happy-path E2E test scenarios covering the primary use cases of each CLI command (`ace-demo` with 6 commands).
3. Ensure proper sandbox setup/teardown for test isolation.
4. Verify all E2E tests pass with `ace-test ace-demo`.

### Success Criteria

- [ ] E2E test directory structure created in `ace-demo/test/e2e/`
- [ ] Happy-path scenarios cover all CLI commands (`ace-demo` with 6 commands)
- [ ] Tests use proper sandbox isolation
- [ ] All E2E tests pass
- [ ] Test patterns consistent with existing E2E tests in other packages

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask (create)
- **Slice Outcome**: `ace-demo` has a new E2E test suite covering its CLI commands
- **Advisory Size**: small
- **Context Dependencies**: `ace-demo` CLI command implementations, existing E2E test patterns in other packages

### Verification Plan

#### Integration / E2E Validation
- [ ] All E2E tests pass: `ace-test ace-demo`
- [ ] CLI commands exercised end-to-end with realistic inputs

#### Verification Commands
- [ ] `ace-test ace-demo`

## Objective

Create initial E2E test coverage for `ace-demo`, which has CLI commands but currently lacks E2E tests.

## Scope of Work

- Scaffold E2E test structure via `/as-e2e-create`
- Create happy-path scenarios for `ace-demo` with 6 commands
- Ensure sandbox isolation and test conventions
- Verify all tests pass

## Out of Scope

- ❌ Changing CLI command behavior
- ❌ Unit test or molecule test changes
- ❌ Comprehensive error-path coverage (happy-path first, expand later)

## References

- Parent: 8qe.t.h5e — Review and expand E2E test coverage across ACE packages
- `/as-e2e-create` workflow
