---
id: v.0.9.0+task.057
status: in-progress
priority: high
estimate: 6h
dependencies: []
---

# Improve ace-test-runner reporter output for Minitest

## Description

The ace-test-runner reporter has several issues when displaying test failures:

1. **Parsing Failure** - Parser doesn't extract failure details from raw Minitest output, resulting in empty failures array
2. **Summary Mismatch** - Status display shows incorrect type (e.g., "FAILURES (0/26)" when should show "ERRORS (26/26)")
3. **Missing Reports** - No failures.json or individual failure .md files are generated
4. **No Fail-Fast** - All errors displayed without configurable limits

This task fixes the reporter to provide compact, accurate output with proper error extraction and fail-fast capabilities.

## Behavioral Specification

**User Experience:**
- When tests fail, user sees up to 10 failures (configurable) with:
  - Relative path to test file with line number
  - Concise error message
  - Path to detailed report in test-reports/
- Summary line shows accurate status: ✅/💥/❌ with correct counts
- After limit, shows "... and N more failures. See full report: {path}"
- Detailed reports available in test-reports/{timestamp}/failures.json and failures/*.md

**Interface Contract:**
```bash
# Default behavior (max 10 failures displayed)
ace-test test/

# Configure limits
ace-test test/ --max-failures-display 5
ace-test test/ --fail-fast  # Stop after 20 failures

# Output format
💥 26 tests, 0 assertions, 0 failures, 26 errors (2.29s)

ERRORS (10/26) → test-reports/latest/failures.json:
  test/organisms/task_manager_test.rb:129 - Expected nil to be truthy
  → Details: test-reports/20251001-180541/failures/001-test-find-task.md
  ...
  ... and 16 more errors. See full report: test-reports/latest/failures.json
```

## Acceptance Criteria

- [ ] Result parser extracts all failure details (test name, file, line, message, type)
- [ ] Summary display distinguishes between failures and errors correctly
- [ ] failures.json generated with complete failure data
- [ ] Individual failure .md files created (up to max_failures_to_display)
- [ ] Configuration supports max_failures_to_display (default: 10)
- [ ] Configuration supports max_failures_before_stop (default: 20)
- [ ] Output shows relative paths (test/path/file.rb:line)
- [ ] "... and N more" message when failures exceed display limit
- [ ] All tests in ace-test-runner pass
- [ ] Testing against ace-taskflow shows correct output for 26 errors

## Implementation Plan

### Planning Steps

* [ ] Analyze current result_parser.rb regex patterns against actual Minitest output
* [ ] Review ace-taskflow raw_output.txt to understand actual error format
* [ ] Design failure_report_writer molecule interface
* [ ] Determine best location for fail-fast logic (runner vs formatter)

### Execution Steps

- [ ] Phase 1: Fix result parsing (ace-test-runner/lib/ace/test_runner/atoms/result_parser.rb)
  - [ ] Debug and fix inline_failure and inline_error regex patterns
  - [ ] Test against ace-taskflow output format
  - [ ] Ensure both FAIL and ERROR types captured with all details
  - [ ] Add tests for parser with sample Minitest output

- [ ] Phase 2: Fix summary display (progress_formatter.rb:50-98)
  - [ ] Distinguish between failures and errors in output
  - [ ] Fix counter to show correct type (ERRORS vs FAILURES vs both)
  - [ ] Test summary line formatting

- [ ] Phase 3: Generate detailed failure reports
  - [ ] Create lib/ace/test_runner/molecules/failure_report_writer.rb
  - [ ] Generate {report_dir}/failures.json with full failures array
  - [ ] Generate {report_dir}/failures/NNN-test-name.md for each failure
  - [ ] Include test name, location, message, stack trace, fix suggestions
  - [ ] Update test_reporter.rb to call failure_report_writer

- [ ] Phase 4: Implement fail-fast configuration
  - [ ] Verify max_failures_to_display configuration exists and is used
  - [ ] Add max_failures_before_stop configuration option
  - [ ] Implement fail-fast logic in in_process_runner.rb
  - [ ] Show "... and X more failures" when limit exceeded

- [ ] Phase 5: Improve output format
  - [ ] Verify relative path extraction works correctly
  - [ ] Ensure failure report path generation works
  - [ ] Test output format matches specification

- [ ] Testing and validation
  - [ ] Run ace-test-runner tests to ensure no regressions
  - [ ] Test against ace-taskflow (26 failing tests)
  - [ ] Verify all 26 errors are parsed correctly
  - [ ] Check failures.json is created with complete data
  - [ ] Verify individual .md reports are generated
  - [ ] Test fail-fast stops execution at threshold
  - [ ] Test max_display limits output correctly

## Implementation Notes

### Current State Analysis

**Files Involved:**
- `ace-test-runner/lib/ace/test_runner/atoms/result_parser.rb` - Parses Minitest output
- `ace-test-runner/lib/ace/test_runner/formatters/progress_formatter.rb` - Formats output
- `ace-test-runner/lib/ace/test_runner/models/test_result.rb` - Result data structure
- `ace-test-runner/lib/ace/test_runner/models/test_failure.rb` - Failure data structure
- `ace-test-runner/lib/ace/test_runner/molecules/in_process_runner.rb` - Test execution

**Root Cause:**
The result parser's regex patterns (lines 13-15 in result_parser.rb) don't match the current Minitest verbose output format. This causes the failures array to be empty, which cascades into all downstream issues.

**Priority:**
Phase 1 (parsing) is critical - fixes root cause. All other phases depend on it.

**Testing Strategy:**
1. Create test fixtures with actual Minitest output samples
2. Test parser in isolation first
3. Integration test with ace-taskflow
4. Verify output format matches specification
