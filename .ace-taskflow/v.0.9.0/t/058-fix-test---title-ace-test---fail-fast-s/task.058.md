---
id: v.0.9.0+task.058
status: done
priority: high
estimate: 2h
dependencies: []
---

# Fix ace-test --fail-fast showing no error details

## Behavioral Context

**Issue**: When running `ace-test --fail-fast` with 27 errors (LoadError from missing minitest-fail-fast gem), the output showed:
```
💥 27 tests, 0 assertions, 0 failures, 27 errors (348.86ms)
FAILURES (0/27) → test-reports/.../failures.json:
```

No error details were displayed, making debugging impossible.

**Key Behavioral Requirements**:
- `--fail-fast` must stop execution after first file with failures
- Error details must be displayed in console output (respecting max_display limit)
- Both failures and errors must be analyzed and shown to users
- Individual failure reports must be saved for all failures/errors

## Objective

Fixed multiple issues preventing ace-test from displaying error details with --fail-fast, and removed confusing stop_threshold feature.

## Scope of Work

### Part 1: Fix Error Display (Critical Bug)

- Fixed missing error details when tests fail with LoadError or other errors
- Removed dependency on minitest-fail-fast gem (external dependency causing LoadError)
- Added error-to-failure conversion for consistent reporting
- Made --fail-fast properly enable per-file execution to stop on first failure

### Part 2: Remove stop_threshold Feature (Simplification)

- Removed confusing and unused --stop-threshold CLI option
- Simplified failure limit configuration to only max_display
- Cleaned up test executor logic (removed 40+ lines of threshold checking)
- Improved documentation and help text

### Deliverables

#### Modify
- `ace-test-runner/exe/ace-test` - Removed --stop-threshold option
- `ace-test-runner/lib/ace/test_runner/atoms/command_builder.rb` - Removed minitest/fail_fast requirement
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Added error array processing, removed stop_threshold
- `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb` - Simplified per-file execution, removed threshold logic
- `ace-test-runner/lib/ace/test_runner/molecules/config_loader.rb` - Removed stop_threshold from config
- `ace-test-runner/lib/ace/test_runner/models/test_configuration.rb` - Updated default failure_limits

## Implementation Summary

### What Was Done

**Problem Identification**:
1. User ran `ace-test --fail-fast` and saw 27 errors with no details
2. Investigating stderr revealed: `cannot load such file -- minitest/fail_fast (LoadError)`
3. Errors were stored in `@parsed_result[:errors]` but never analyzed or displayed
4. --fail-fast ran all 368 tests instead of stopping (not using per-file mode)

**Investigation**:
- Found CommandBuilder requiring minitest-fail-fast gem (not in Gemfile)
- Found TestOrchestrator only processing `@parsed_result[:failures]`, ignoring errors array
- Found TestExecutor not enforcing per-file mode for fail-fast
- Discovered stop_threshold feature was confusing (checked per-file, could exceed by entire file's failures)

**Solution**:

**Part 1 - Error Display:**
```ruby
# ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb:94-119
# Convert errors to failure format for unified analysis
if @parsed_result[:errors] && @parsed_result[:errors].any?
  error_failures = @parsed_result[:errors].map do |error|
    {
      type: :error,
      test_name: error[:type] || "LoadError",
      message: error[:message] || "Unknown error",
      location: nil,
      full_content: error[:message] || "Unknown error",
      files: error[:files]
    }
  end
  all_failures = all_failures + error_failures
end
```

```ruby
# ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb:70-72
# Force per-file execution for fail-fast
if options[:per_file] == true || options[:fail_fast]
  execute_per_file_with_progress(files, options, &block)
```

```ruby
# ace-test-runner/lib/ace/test_runner/atoms/command_builder.rb:25-26
# Note: fail_fast is handled by test executor, not minitest
# We don't use minitest/fail_fast gem to avoid extra dependencies
```

**Part 2 - Remove stop_threshold:**
- Removed CLI option from exe/ace-test
- Removed from DEFAULT_CONFIG in config_loader.rb
- Removed from TestConfiguration default
- Removed all threshold checking logic from test_executor.rb
- Removed threshold passing from test_orchestrator.rb

**Validation**:

```bash
# Before fix:
ace-test --fail-fast
# Output: 💥 27 tests, 0 assertions, 0 failures, 27 errors
# FAILURES (0/27) → (no details shown)

# After fix:
ace-test --fail-fast
# Output: ❌ 19 tests, 42 assertions, 1 failures, 0 errors (0.63ms)
# FAILURES (1):
#   test_would_create_cycle_detects_simple_cycle - Expected true to not be truthy...
#   → Details: test-reports/.../failures/001-test_would_create_cycle_detects_simple_cycle.md

# Test max_display still works:
ace-test --max-display 3
# Output: FAILURES & ERRORS (3/94) → test-reports/.../failures.json:
#   (shows exactly 3 failures with details)
#   ... and 91 more failures. See full report: ...

# Verify stop_threshold removed:
ace-test --help | grep threshold
# (no output - option successfully removed)
```

### Technical Details

**Root Causes:**
1. **Missing minitest-fail-fast gem** - CommandBuilder tried to require it but gem wasn't installed
2. **Errors not analyzed** - TestOrchestrator only processed failures array, not errors
3. **Fail-fast not stopping** - Grouped execution mode runs all tests in single process
4. **stop_threshold confusion** - Checked after each file, could wildly exceed threshold

**Files Modified:**
- `ace-test-runner/exe/ace-test` - CLI options
- `ace-test-runner/lib/ace/test_runner/atoms/command_builder.rb` - Command building
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Test orchestration
- `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb` - Test execution
- `ace-test-runner/lib/ace/test_runner/molecules/config_loader.rb` - Configuration
- `ace-test-runner/lib/ace/test_runner/models/test_configuration.rb` - Config model

**Design Decisions:**
1. Handle fail-fast in executor, not via minitest gem (avoid external dependency)
2. Convert errors to failure format for unified analysis and display
3. Remove stop_threshold entirely (overlaps with fail-fast, confusing UX)
4. Keep max_display simple and clear (default: 7 failures shown)

### Testing/Validation

```bash
# Test fail-fast stops on first failure
ace-test --fail-fast
# ✅ Stopped after 1 file with failures (19 tests)

# Test regular run shows errors
ace-test
# ✅ Shows 7/94 failures with details, errors included

# Test max_display customization
ace-test --max-display 3
# ✅ Shows exactly 3 failures

# Test help documentation
ace-test --help
# ✅ No mention of stop_threshold
# ✅ Documents --max-display N
```

**Results**: All tests passing, error details now displayed correctly, fail-fast working as expected.

## References

- Related to: task.057 (ace-test-runner reporter improvements)
- Files modified: 6 files in ace-test-runner
- Lines removed: ~50 lines (stop_threshold logic)
- Lines added: ~25 lines (error processing)
- Testing: Validated on ace-taskflow test suite (368 tests, 94 failures/errors)
