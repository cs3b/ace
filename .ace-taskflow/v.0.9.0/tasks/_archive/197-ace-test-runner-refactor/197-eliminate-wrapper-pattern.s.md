---
id: v.0.9.0+task.197
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Refactor ace-test-runner to eliminate wrapper pattern

## 0. Directory Audit

_Command run:_

```bash
ls -la ace-test-runner/lib/ace/test_runner/commands/
```

_Result excerpt:_

```
test.rb           # dry-cli command wrapper (delegates to TestCommand)
test_command.rb   # Business logic (instance methods, 200+ lines)
```

## Behavioral Specification

### User Experience
- **Input**: Users run `ace-test` or `ace-test atoms`
- **Process**: Command executes correctly without wrapper layer
- **Output**: Tests executed with results displayed

### Expected Behavior

ace-test-runner uses wrapper pattern passing through to `TestCommand`. Merge wrapper and logic into single command class.

**Commands to Refactor:**
```bash
ace-test [pattern] [options]    # Run tests
```

### Success Criteria

- [ ] **Test command refactored**: Wrapper merged with TestCommand
- [ ] **Help text works**: `ace-test --help` shows proper documentation
- [ ] **Tests pass**: All tests updated
- [ ] **No functional changes**: Command works exactly as before

## Objective

Eliminate wrapper pattern in ace-test-runner by merging wrapper and business logic into single dry-cli command class.

## Scope of Work

- **User Experience Scope**: ace-test CLI command
- **System Behavior Scope**: Command execution, test running logic

### Deliverables

#### Refactored Commands
- `lib/ace/test_runner/commands/test.rb` (merged)

#### Deleted Files
- `lib/ace/test_runner/commands/test_command.rb`

## Technical Approach

### Architecture Pattern
- [x] Pattern selection: Inline business logic in dry-cli Command class
- [x] Integration: Follows ace-timestamp pattern (cli/encode.rb + commands/encode_command.rb)
- [x] Impact: Reduces indirection, single file contains CLI definition and execution logic

### Current vs Target Structure

**Current (wrapper pattern):**
```
commands/
├── test.rb           # dry-cli Command (thin wrapper)
│   └── call() → TestCommand.new(args, options).execute()
└── test_command.rb   # Business logic class (instance methods)
    ├── initialize(args, options)
    ├── execute()
    ├── build_test_options()
    ├── handle_special_modes()
    ├── handle_cleanup_reports()
    ├── handle_rake_integration()
    ├── handle_fix_deprecations()
    ├── run_tests_with_exit_handling()
    └── display_config_summary()
```

**Target (merged pattern):**
```
commands/
└── test.rb           # dry-cli Command with ALL logic inline
    ├── call(args:, **options) - entry point
    ├── private methods moved from TestCommand
    └── All business logic in single file
```

### Implementation Strategy
- Move all methods from `test_command.rb` into `test.rb` as private methods
- Convert instance variables to local variables or method parameters
- Keep `call()` as entry point, move `execute()` logic into it
- Update tests to use `Commands::Test` instead of `Commands::TestCommand`

## File Modifications

### Modify
- `ace-test-runner/lib/ace/test_runner/commands/test.rb`
  - Changes: Merge all logic from test_command.rb
  - Impact: Single file contains all test command logic
  - Integration: Continues to work with CLI registry unchanged

### Delete
- `ace-test-runner/lib/ace/test_runner/commands/test_command.rb`
  - Reason: Logic merged into test.rb
  - Dependencies: test.rb will contain all logic
  - Migration: Direct move of methods

### Update Tests
- `ace-test-runner/test/commands/cleanup_config_test.rb`
  - Changes: Update `TestCommand.new` to use new pattern
  - Current usage:
    ```ruby
    command = Ace::TestRunner::Commands::TestCommand.new([], { cleanup_reports: true })
    command.execute
    ```
  - New usage: Call via CLI or use internal API

## Implementation Plan

### Planning Steps

* [x] Analyze current test.rb wrapper structure
* [x] Analyze test_command.rb business logic structure
* [x] Review reference pattern (ace-timestamp encode command)
* [x] Identify test file dependencies on TestCommand class

### Execution Steps

- [ ] Step 1: Merge test_command.rb methods into test.rb
  - Move all private methods from TestCommand into Test class
  - Convert instance variables (@args, @options) to method parameters
  - Keep method signatures compatible
  > TEST: Methods Moved
  > Type: Action Validation
  > Assert: All methods from TestCommand exist in Test class
  > Command: grep -c "def " ace-test-runner/lib/ace/test_runner/commands/test.rb

- [ ] Step 2: Update call() method to inline execute() logic
  - Move execute() logic directly into call()
  - Maintain error handling and special mode checks
  > TEST: Call Method Updated
  > Type: Action Validation
  > Assert: call() contains execute logic
  > Command: ace-test ace-test-runner

- [ ] Step 3: Update test file (cleanup_config_test.rb)
  - Replace TestCommand.new with CLI-compatible approach
  - Option A: Call via CLI.start
  - Option B: Create test helper method
  > TEST: Tests Updated
  > Type: Action Validation
  > Assert: Tests use new pattern
  > Command: grep -c "TestCommand" ace-test-runner/test/

- [ ] Step 4: Delete test_command.rb
  - Remove file after all logic migrated
  - Remove require statement from test.rb
  > TEST: File Removed
  > Type: Action Validation
  > Assert: test_command.rb no longer exists
  > Command: test ! -f ace-test-runner/lib/ace/test_runner/commands/test_command.rb

- [ ] Step 5: Run full test suite
  > TEST: All Tests Pass
  > Type: Action Validation
  > Assert: All tests pass
  > Command: cd ace-test-runner && ace-test

- [ ] Step 6: Verify CLI functionality
  > TEST: CLI Works
  > Type: Action Validation
  > Assert: ace-test --help shows documentation
  > Command: ace-test --help

## Risk Assessment

### Technical Risks
- **Risk:** Test file directly instantiates TestCommand
  - **Probability:** High (confirmed in cleanup_config_test.rb)
  - **Impact:** Medium (tests will fail until updated)
  - **Mitigation:** Update tests in same commit as refactor
  - **Rollback:** Revert commit if tests cannot be fixed

### Integration Risks
- **Risk:** CLI behavior changes unexpectedly
  - **Probability:** Low (dry-cli routing unchanged)
  - **Impact:** High (user-facing command)
  - **Mitigation:** Manual verification of ace-test --help and ace-test atoms
  - **Monitoring:** CI will catch regressions

## Acceptance Criteria

- [ ] AC 1: test_command.rb deleted
- [ ] AC 2: test.rb contains all business logic (>200 lines)
- [ ] AC 3: All tests in ace-test-runner pass
- [ ] AC 4: `ace-test --help` shows proper documentation
- [ ] AC 5: `ace-test atoms` runs successfully (in a valid package)

## Out of Scope

- ❌ **New functionality**: No new features
- ❌ **Test execution logic**: No changes to how tests run
- ❌ **Other commands**: Only test command affected

## References

- Reference pattern: `ace-timestamp/lib/ace/timestamp/cli/encode.rb`
- Reference command class: `ace-timestamp/lib/ace/timestamp/commands/encode_command.rb`
- ADR pattern: dry-cli migration (Task 179)
