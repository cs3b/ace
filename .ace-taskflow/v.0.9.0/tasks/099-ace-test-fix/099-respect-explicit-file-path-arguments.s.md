---
id: v.0.9.0+task.099
status: draft
priority: high
estimate: 2-4 hours
dependencies: []
---

# Fix ace-test to respect explicit file path arguments

## Behavioral Specification

### User Experience
- **Input**: Developer or AI agent provides explicit test file path(s) as CLI arguments (e.g., `ace-test test/atoms/foo_test.rb`)
- **Process**: Test runner executes ONLY the specified file(s), providing fast feedback with clear output showing which files are running
- **Output**: Test results and timing information for only the explicitly specified files, not the entire test suite or configured groups

### Expected Behavior

When a user runs `ace-test` with an explicit file path, the tool should execute only that specific test file, bypassing any configured test groups or suites. This enables fast, focused testing during development and debugging.

**Current broken behavior:**
- Running `ace-test test/atoms/path_expander_test.rb` executes all configured test groups (smoke, atoms, etc.)
- Developer sees "Running smoke (2 files)..." and "Running atoms (2 files)..." even though only one file was requested
- Test execution takes significantly longer than necessary
- Feedback loop is slowed, reducing development efficiency

**Expected correct behavior:**
- Running `ace-test test/atoms/path_expander_test.rb` executes ONLY that single file
- Output clearly indicates the specific file being executed
- Test execution completes quickly with focused results
- Configured groups are completely bypassed when explicit files are provided

### Interface Contract

```bash
# Single file execution - should run ONLY this specific file
$ ace-test test/atoms/foo_test.rb
Running test/atoms/foo_test.rb...
✓ Complete (45.2ms, 12 tests, 0 failures)

# File with line number - should run ONLY the test at that line
$ ace-test test/atoms/foo_test.rb:42
Running test/atoms/foo_test.rb:42...
✓ Complete (8.1ms, 1 test, 0 failures)

# Multiple explicit files - should run ONLY these files
$ ace-test test/atoms/foo_test.rb test/molecules/bar_test.rb
Running 2 files...
✓ Complete (67.3ms, 24 tests, 0 failures)

# No arguments - should preserve current group-based execution (no change)
$ ace-test
Running smoke (2 files)...
✓ smoke complete (53.8ms, 6 tests, 0 failures)
Running atoms (12 files)...
✓ atoms complete (241.5ms, 48 tests, 0 failures)
```

**Error Handling:**
- **File not found**: `Error: Test file not found: test/atoms/missing_test.rb`
- **Invalid line number**: `Error: No test found at test/atoms/foo_test.rb:999`
- **Non-test file**: `Error: Not a test file: lib/ace/foo.rb` (optional, may just return 0 tests)

**Edge Cases:**
- **Mixed arguments** (file + group): Explicit files take precedence, ignore group
- **Empty file**: Run the file, report 0 tests executed
- **File outside test directory**: Allow if valid test file, execute normally

### Success Criteria

- [ ] **Explicit file filtering**: Running `ace-test path/to/test.rb` executes ONLY that file
- [ ] **Line number filtering**: Running `ace-test path/to/test.rb:42` executes ONLY that specific test
- [ ] **Multiple file filtering**: Running `ace-test file1.rb file2.rb` executes ONLY those files
- [ ] **Output clarity**: Test output clearly indicates which specific files are being executed
- [ ] **Performance improvement**: Execution time reflects only the filtered files (not all groups)
- [ ] **Group execution preserved**: Running `ace-test` with no arguments continues to use configured groups
- [ ] **Configuration override**: Explicit files override any `.ace/test/runner.yml` group configuration
- [ ] **Deterministic behavior**: Same arguments always produce same file selection

### Validation Questions

- [x] **Precedence rules**: File paths always take precedence over group targets. When both are provided, only the explicit files are executed.
- [x] **Glob patterns**: Deferred to future enhancement. Only explicit file paths are supported in this task.
- [x] **Test method filtering**: Deferred to future enhancement. Only line number filtering is supported in this task.
- [x] **Exit code behavior**: Exit codes remain the same (0 for success, 1 for failures) regardless of filtering mode.
- [x] **Reporting format**: Test reports should maintain the same structure but only include results from the executed files.

## Objective

Enable developers and AI agents to run focused, efficient tests by respecting explicit file path arguments, dramatically improving the feedback loop during development and debugging. This aligns with ACE's commitment to deterministic, focused CLI tools that enhance both human and AI workflows.

## Scope of Work

### User Experience Scope
- **Focused test execution**: Users can run single files, multiple files, or specific line numbers
- **Fast feedback loops**: Test execution time reflects only the filtered scope
- **Clear output**: Users immediately understand which tests are running
- **Predictable behavior**: CLI arguments consistently override configuration

### System Behavior Scope
- **File path filtering**: System respects explicit file paths provided via CLI
- **Line number filtering**: System supports `file:line` syntax for granular test selection
- **Group bypass**: System skips group/suite expansion when explicit files are provided
- **Configuration override**: System prioritizes CLI arguments over configuration file settings

### Interface Scope
- **CLI argument parsing**: `ace-test [file-paths]` and `ace-test [file:line]` formats
- **Output formatting**: Clear indication of which files are being executed
- **Exit codes**: Standard success (0) and failure (1) codes
- **Error messages**: Clear feedback for invalid file paths or line numbers

### Deliverables

#### Behavioral Specifications
- User experience flow for explicit file execution
- System behavior when CLI arguments override configuration
- Interface contract for file and line number filtering
- Precedence rules for argument types (files vs groups vs defaults)

#### Validation Artifacts
- Success criteria validation through manual testing scenarios
- User acceptance scenarios covering all filtering modes
- Behavioral test cases for file filtering in grouped execution mode

### Implementation Approach

**Key Integration Points:**
- The primary fix is expected to be in `TestOrchestrator#should_execute_sequentially?` method
- CLI argument parsing and file preservation logic appears to be working correctly
- The bug occurs when the system decides between group execution vs explicit file execution

**Likely Files to be Modified:**
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Core logic fix
- `ace-test-runner/exe/ace-test` - Potential CLI validation improvements
- `ace-test-runner/test/integration/` - New test coverage

**Testing Strategy:**
- Create integration tests that verify the behavioral specification
- Test both positive scenarios and error conditions
- Ensure no regression to existing group-based execution

### Validation Test Scenarios

**Positive Test Cases:**
1. `ace-test test/atoms/path_expander_test.rb` → Should run only that file
2. `ace-test test/atoms/path_expander_test.rb:42` → Should run only test at line 42
3. `ace-test test/atoms/path_expander_test.rb test/molecules/config_loader_test.rb` → Should run only those 2 files
4. `ace-test` (no arguments) → Should run groups as before (no regression)

**Error Test Cases:**
1. `ace-test test/atoms/nonexistent_test.rb` → Should show "Test file not found" error
2. `ace-test test/atoms/path_expander_test.rb:999` → Should show "No test found at line" error
3. `ace-test lib/ace/foo.rb` → Should show "Not a test file" error

**Precedence Test Cases:**
1. `ace-test atoms test/atoms/path_expander_test.rb` → Should run only the specified file, ignore group
2. `ace-test test/atoms/path_expander_test.rb smoke` → Should run only the specified file, ignore group

## Out of Scope

- ❌ **Implementation Details**: Changes to TestOrchestrator, execution mode logic, or internal architecture
- ❌ **Technology Decisions**: How filtering is implemented, which classes are modified, or technical refactoring approach
- ❌ **Performance Optimization**: Specific performance tuning beyond respecting filtered file scope
- ❌ **Future Enhancements**:
  - Glob pattern support in CLI arguments
  - Test method name filtering (beyond line numbers)
  - Advanced filtering DSL or query language
  - Watch mode or continuous testing features
  - Parallel execution optimization
  - Test result caching

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251105-130450-ace-test-fix/filter-runner-for-single-file-execution.s.md`
- Related gem: `ace-test-runner/`
- Bug example output showing current broken behavior documented in idea file
- ACE testing patterns: `docs/testing-patterns.md`
