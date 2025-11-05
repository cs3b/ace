---
id: v.0.9.0+task.099
status: draft
priority: high
estimate: TBD
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

- [ ] **Precedence rules**: What happens if user provides both a file path AND a group target (e.g., `ace-test atoms test/atoms/foo_test.rb`)? Should file paths always take precedence?
- [ ] **Glob patterns**: Should we support glob patterns as explicit arguments (e.g., `ace-test test/atoms/*_test.rb`)? Or is that a separate enhancement?
- [ ] **Test method filtering**: Should we support running specific test methods by name (e.g., `ace-test file.rb --name test_foo`)? Or only line numbers for now?
- [ ] **Exit code behavior**: Should exit codes remain the same (0 for success, 1 for failures) regardless of filtering mode?
- [ ] **Reporting format**: Should the test report directory structure change when running explicit files vs groups?

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
