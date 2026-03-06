---
name: test/plan
description: Plan test coverage before writing code - decide what to test at each layer
allowed-tools: Read, Bash, Grep, Glob, Bash(ace-search:*), Bash(ace-bundle:*)
argument-hint: 'feature description or task specification'
doc-type: workflow
purpose: Ensure comprehensive test coverage with tests at the right layer
params:
  feature: Description of feature or change being implemented
  files: List of files that will be modified
tools:
  - ace-search
  - ace-bundle
embed_document_source: false
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Plan Tests Workflow

## Purpose

Before writing code, plan what tests are needed at each layer. This prevents:
- Missing test coverage
- Tests at the wrong layer (slow unit tests, missing E2E)
- Duplicate testing of same behavior at multiple layers

This workflow embodies the **Test Planner** role (deciding WHAT and WHERE to test).
The **Test Writer** role (implementing tests) follows separately.

## Roles

### Test Planner (This Workflow)

**Focus**: Strategic decisions
- WHAT behaviors need testing
- WHERE (which layer) each belongs
- WHAT risk level applies
- WHAT fixtures/contracts are needed

**Output**: Test Responsibility Map

### Test Writer (Separate)

**Focus**: Tactical implementation
- HOW to implement each test
- HOW to stub dependencies
- HOW to assert results
- HOW to maintain performance (<100ms)

**Output**: Test files

## When to Use

- Before implementing a new feature
- Before fixing a bug (plan regression test)
- When reviewing existing test coverage
- As part of `/as-task-work` workflow

## Input

- Feature description or task specification
- List of files to be modified
- Existing test coverage (optional)

## Workflow Steps

### Step 1: Understand the Change

Analyze the feature/change to identify:

1. **Pure logic components** (algorithms, transformations, validations)
2. **Integration points** (component interactions, data flow)
3. **External dependencies** (filesystem, network, subprocess, git)
4. **User-facing behavior** (CLI output, exit codes, error messages)

```
Questions to answer:
- What new functions/methods will be added?
- What existing behavior might change?
- What external systems are involved?
- What are the error scenarios?
```

### Step 2: Identify Behaviors to Test

For each component, list specific behaviors:

```markdown
## Behaviors to Test

### Component: ConfigParser
- [ ] Parses valid YAML file
- [ ] Returns default values for missing keys
- [ ] Raises error for malformed YAML
- [ ] Handles empty file gracefully

### Component: WorkflowOrchestrator
- [ ] Executes steps in order
- [ ] Stops on first failure
- [ ] Reports partial progress on failure
- [ ] Handles empty step list
```

### Step 3: Assign Risk Levels

For each behavior, assess risk:

| Risk Level | Criteria | Coverage Required |
|------------|----------|-------------------|
| **High** | Security, data integrity, core business, user-facing errors | Unit + E2E |
| **Medium** | Important functionality, configuration | Unit required |
| **Low** | Logging, cosmetic, internal helpers | Unit if time permits |

Example:

| Behavior | Risk | Why |
|----------|------|-----|
| Parse valid YAML | Medium | Core functionality |
| Malformed YAML error | High | User-facing error handling |
| CLI exit codes | High | User workflow |
| Debug logging | Low | Internal only |

### Step 4: Classify by Test Layer

For each behavior, decide the appropriate layer:

| Behavior | Risk | Layer | Rationale |
|----------|------|-------|-----------|
| Parse valid YAML | Medium | Unit | Pure function, no I/O |
| Default values for missing keys | Medium | Unit | Data transformation |
| Malformed YAML error | High | Unit | Error handling |
| Steps execute in order | Medium | Integration | Component interaction |
| CLI shows progress | High | E2E | User-facing behavior |

**Decision criteria**:

```
Unit Test if:
- Pure logic, no side effects
- Can be tested with simple input/output
- No external dependencies needed

Integration Test if:
- Multiple components interact
- Needs controlled I/O (temp files)
- Tests error propagation

E2E Test if:
- Tests complete user workflow
- Requires real external tools
- Validates CLI behavior
```

### Step 5: Define Mock Strategy

For each non-E2E test, identify what to mock:

```markdown
## Mock Strategy

### Unit Tests
- Stub `FileSystem.read` with test content
- Stub `Time.now` for timestamp tests
- Use `MockGitRepo` for commit data

### Integration Tests
- Stub `Open3.capture3` for subprocess calls
- Stub `WebMock` for API calls
- Use temp directory for file operations

### What NOT to Mock
- The system under test itself
- Simple value objects
- Pure functions
```

### Step 6: Identify Edge Cases

For each behavior, list edge cases:

```markdown
## Edge Cases

### ConfigParser
- Empty string input
- Nil input
- Very large file (>1MB)
- Unicode characters in keys
- Circular references

### WorkflowOrchestrator
- Zero steps
- 100+ steps
- Step throws exception
- Step returns nil
- Concurrent execution
```

### Step 7: Check for Existing Coverage

Search for existing tests:

```bash
# Find existing tests for the component
ace-search "class ConfigParser" --type test
ace-search "def test.*config" --type test
```

Identify:
- Tests that already cover some behaviors
- Tests that need updating
- Gaps in coverage

### Step 8: Generate Test Responsibility Map

Output the Test Responsibility Map document:

```markdown
# Test Responsibility Map: [Feature Name]

## Summary
- Total behaviors: N
- High risk: N (require E2E coverage)
- Unit tests planned: N
- Integration tests planned: N
- E2E tests planned: N

## Responsibility Matrix

| Behavior | Risk | Layer | Test File | Source of Truth |
|----------|------|-------|-----------|-----------------|
| Parse valid YAML | Medium | Unit | config_parser_test.rb | YAML schema |
| Malformed YAML error | High | Unit | config_parser_test.rb | Error messages |
| CLI exit codes | High | E2E | TS-CONFIG-001 | CLI spec |

## Unit Tests (atoms/molecules)

### File: test/atoms/config_parser_test.rb

#### test_parses_valid_yaml
- Input: Valid YAML string
- Expected: Parsed hash with correct values
- Mocks: None (pure function)

#### test_returns_defaults_for_missing_keys
- Input: YAML without optional keys
- Expected: Hash with default values filled
- Mocks: None

#### test_raises_on_malformed_yaml
- Input: Invalid YAML syntax
- Expected: ParseError with line number
- Mocks: None

## Integration Tests (organisms)

### File: test/organisms/workflow_orchestrator_test.rb

#### test_executes_steps_in_order
- Setup: Create 3 mock steps
- Action: Execute orchestrator
- Verify: Steps called in order
- Mocks: Step executors

#### test_stops_on_first_failure
- Setup: Step 2 returns failure
- Action: Execute orchestrator
- Verify: Step 3 not called, error reported
- Mocks: Step executors

## E2E Tests

### Directory: test/e2e/TS-FEATURE-001-workflow-execution/

#### TC-001: Complete workflow success
- Steps: Create config, run CLI, verify output
- Expected: Exit 0, output contains success message

#### TC-002: Workflow failure handling
- Steps: Create invalid config, run CLI
- Expected: Exit 1, error message is actionable

## Mock Data Needed

- fixtures/valid_config.yml
- fixtures/malformed_config.yml
- fixtures/large_config.yml

## Composite Helpers Needed

- with_mock_steps(count:, failing_at:)
- with_temp_config(content:)
```

## Output

The test plan should be saved to:
- Task folder: `.ace-taskflow/.../task-XXX/test-plan.md`
- Or reviewed in conversation before implementation

## Checklist Before Implementation

- [ ] All new behaviors have tests planned
- [ ] Tests are at appropriate layers
- [ ] Edge cases identified
- [ ] Mock strategy defined
- [ ] No duplicate testing across layers
- [ ] E2E tests cover critical user paths only

## Integration with Other Workflows

### With /as-task-work

1. Load task specification
2. **Run /as-test-plan**
3. Implement feature
4. Write tests according to plan
5. Verify coverage

### With /as-test-create-cases

Use this workflow first to plan, then `/as-test-create-cases` to generate test code.

## See Also

- [Test Layer Decision Guide](guide://test-layer-decision)
- [Test Responsibility Map Guide](guide://test-responsibility-map)
- [Test Mocking Patterns Guide](guide://test-mocking-patterns)
- [Test Review Checklist](guide://test-review-checklist)
- [Create Test Cases Workflow](wfi://test/create-cases)
- [Verify Test Suite Workflow](wfi://test/verify-suite)
