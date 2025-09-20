---
id: v.0.9.0+task.012
status: in-progress
priority: high
estimate: 4h
dependencies: []
---

# Improve ace-test-runner progress reporting with per-test and per-file formats

## Behavioral Specification

### User Experience
- **Input**: Developers run ace-test-runner with existing or new progress format options
- **Process**: Test execution shows real-time progress with accurate per-test or per-file indicators
- **Output**: Clear progress dots during execution, accurate failure reporting with proper details

### Expected Behavior

The ace-test-runner should provide two distinct progress reporting formats that give developers accurate feedback about test execution:

1. **Per-Test Progress (`progress` format - default)**: Shows individual dots for each test executed (., F, E, S) providing granular feedback about test status. When a single test fails, only that test shows as F while others show as successful dots.

2. **Per-File Progress (`progress-file` format)**: Shows dots per test file (., F) providing file-level feedback. When any test in a file fails, the entire file shows as F.

3. **Accurate Failure Reporting**: When tests fail, the system shows proper failure details with file location, line number, and clear error messages instead of generic failure indicators.

4. **Consistent Output Format**: Both formats maintain the compact 2-line output style after progress dots for CI/automation compatibility.

### Interface Contract

```bash
# Current default behavior (unchanged)
ace-test-runner
# Shows per-test progress: ....F..E..S (83 dots for 83 tests)
# Output: Progress dots, then 2-line summary

# New explicit per-test format
ace-test-runner --format progress
# Shows per-test progress: ....F..E..S (83 dots for 83 tests)
# Same as default but explicitly specified

# New per-file format
ace-test-runner --format progress-file
# Shows per-file progress: .......F.... (11 dots for 11 files)
# Faster execution using grouped file execution

# Compact format (existing - unchanged)
ace-test-runner --format compact
# Shows per-file progress with existing behavior
```

**Progress Indicators:**
- `.` (dot): Test/file passed
- `F` (F): Test/file failed
- `E` (E): Test/file error (per-test only)
- `S` (S): Test/file skipped (per-test only)

**Failure Details Format:**
```
FAILURES (1):
  test/atoms/env_parser_test.rb:50 - Expected "path\\to\\file" got nil
```

**Error Handling:**
- **Invalid format specified**: Shows available formats and exits with error
- **Test execution failure**: Proper error details with file location and line number
- **No tests found**: Clear message indicating no tests to run

**Edge Cases:**
- **Single test failure in file**: per-test shows single F, per-file shows file F
- **All tests pass**: All dots, successful summary
- **Mixed results**: Appropriate mix of ., F, E, S indicators

### Success Criteria

- [ ] **Per-Test Progress Accuracy**: Default progress format shows individual dots for each test (83 dots for 83 tests), with only failed tests showing F
- [ ] **Per-File Progress Option**: `--format progress-file` shows dots per test file (11 dots for 11 files) with fast grouped execution
- [ ] **Accurate Failure Reporting**: Failed tests show proper details: `test/atoms/env_parser_test.rb:50 - Expected "path\\to\\file" got nil`
- [ ] **Format Compatibility**: Both formats maintain compact 2-line output style after dots for CI integration
- [ ] **Performance Optimization**: per-file format uses grouped execution for faster performance compared to per-test format
- [ ] **Backward Compatibility**: Existing compact format behavior remains unchanged
- [ ] **Default Behavior**: Running `ace-test-runner` without format flag defaults to per-test progress

### Validation Questions

- [ ] **Format Selection Logic**: Should the per-test format be the new default, or should compact remain default?
- [ ] **Performance Trade-off**: Is the performance difference between per-test and per-file execution acceptable for the accuracy benefit?
- [ ] **Error Detail Level**: Should error details be truncated for extremely long messages, and if so, what's the character limit?
- [ ] **CI Integration**: Do both formats need to maintain identical 2-line summary format for existing CI pipeline compatibility?
- [ ] **Intentional Test Failure**: Should the typo in env_parser_test.rb be preserved for testing the formatter, and how should this be documented?

## Objective

Improve developer experience by providing accurate, granular test progress reporting. The current ace-test-runner shows misleading progress (dots per file instead of per test) and broken failure reporting (all dots show F when only one test fails). This enhancement provides both detailed per-test feedback for development and fast per-file feedback for CI, with proper failure details that help developers quickly identify and fix issues.

## Scope of Work

- **User Experience Scope**: Progress format selection, real-time progress feedback, accurate failure reporting
- **System Behavior Scope**: Per-test and per-file progress indicators, execution strategy optimization, failure detail formatting
- **Interface Scope**: CLI format flag, progress output, failure detail output

### Deliverables

#### Behavioral Specifications
- Per-test progress format with individual test indicators
- Per-file progress format with file-level indicators
- Enhanced failure reporting with location and message details
- CLI interface for format selection

#### Validation Artifacts
- Format selection validation (invalid format handling)
- Progress accuracy validation (correct dot count and meaning)
- Failure detail validation (proper file location and message extraction)
- Performance comparison between execution strategies

## Out of Scope

- ❌ **Implementation Details**: Specific formatter class structure, internal progress tracking mechanisms
- ❌ **Technology Decisions**: Choice of progress tracking libraries or execution frameworks
- ❌ **Performance Optimization**: Specific performance improvement strategies beyond execution grouping
- ❌ **Future Enhancements**: Custom progress indicators, colored output themes, progress bars

## Technical Approach

### Architecture Pattern
- [ ] **Formatter Strategy Pattern**: Extend existing CompactFormatter with ProgressFormatter and ProgressFileFormatter
- [ ] **Execution Strategy**: Use existing TestExecutor per_file option for file-level progress and implement per-test execution for granular progress
- [ ] **Interface Enhancement**: Add format parameter to CLI with validation and defaults

### Technology Stack
- [ ] **Ruby Minitest Integration**: Parse minitest output to extract individual test results for per-test progress
- [ ] **Progress Tracking**: Build on existing CompactFormatter's on_test_complete pattern with enhanced per-test callbacks
- [ ] **CLI Enhancement**: Use existing dry-cli framework to add format parameter
- [ ] **Output Parsing**: Parse minitest stdout to extract test count, failure details, and status

## File Modifications

### Create
- `lib/ace/test_runner/formatters/progress_formatter.rb`
  - Purpose: New formatter for per-test progress reporting (default)
  - Key components: Per-test progress tracking, individual test parsing, dot output
  - Dependencies: BaseFormatter, minitest output parsing

- `lib/ace/test_runner/formatters/progress_file_formatter.rb`
  - Purpose: New formatter for per-file progress reporting
  - Key components: File-level progress tracking, grouped execution, file success/failure
  - Dependencies: BaseFormatter, existing TestExecutor per_file option

### Modify
- `exe/ace-test-runner`
  - Changes: Add --format flag with progress, progress-file, compact options
  - Impact: Enhanced CLI interface for format selection
  - Integration points: Formatter selection logic

- `lib/ace/test_runner/molecules/test_executor.rb`
  - Changes: Enhance execute_with_progress to support per-test callbacks for detailed progress
  - Impact: Enable granular test-by-test progress reporting
  - Integration points: Progress formatters, minitest output parsing

- `lib/ace/test_runner/formatters/compact_formatter.rb`
  - Changes: Ensure existing compact format remains unchanged and as fallback
  - Impact: Maintain backward compatibility
  - Integration points: Format selection system

## Implementation Plan

### Planning Steps

* [ ] **Analyze Current Progress System**: Understand existing CompactFormatter per-file progress implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current progress tracking mechanism and formatter pattern identified
  > Command: cd ace-test-runner && grep -r "on_test_complete" lib/

* [ ] **Research Minitest Output Parsing**: Investigate how to extract individual test results from minitest stdout
  > TEST: Parsing Strategy Validation
  > Type: Design Review
  > Assert: Method to extract test count and individual results identified
  > Command: cd ace-test-runner && ruby -e "require 'minitest'; puts Minitest::Runnable.methods.grep(/test/)"

* [ ] **Design Format Selection Architecture**: Plan CLI format parameter and formatter instantiation
  > TEST: CLI Design Validation
  > Type: Interface Check
  > Assert: Format selection integrates with existing CLI structure
  > Command: cd ace-test-runner && grep -r "dry-cli" lib/ exe/

### Execution Steps

- [ ] **Create Progress Formatter Base**: Implement shared progress formatter functionality
  > TEST: Base Formatter Creation
  > Type: Structural Validation
  > Assert: Progress formatter base class exists with required methods
  > Command: cd ace-test-runner && ruby -r "./lib/ace/test_runner/formatters/progress_formatter.rb" -e "puts Ace::TestRunner::Formatters::ProgressFormatter.new"

- [ ] **Implement Per-Test Progress Formatter**: Create formatter that shows dots per individual test
  > TEST: Per-Test Progress Validation
  > Type: Functional Validation
  > Assert: Per-test formatter shows correct number of dots (83 for 83 tests)
  > Command: cd ace-test-runner && bundle exec ace-test-runner --format progress | grep -o "\." | wc -l

- [ ] **Implement Per-File Progress Formatter**: Create formatter that shows dots per test file
  > TEST: Per-File Progress Validation
  > Type: Functional Validation
  > Assert: Per-file formatter shows correct number of dots (11 for 11 files)
  > Command: cd ace-test-runner && bundle exec ace-test-runner --format progress-file | grep -o "\." | wc -l

- [ ] **Add CLI Format Parameter**: Implement --format flag with validation and defaults
  > TEST: CLI Format Selection
  > Type: Interface Validation
  > Assert: Format parameter works with progress, progress-file, compact options
  > Command: cd ace-test-runner && bundle exec ace-test-runner --help | grep -A 3 format

- [ ] **Enhance Failure Reporting**: Implement proper failure details with file location and message
  > TEST: Failure Detail Validation
  > Type: Error Handling Validation
  > Assert: Failures show format "test/atoms/env_parser_test.rb:50 - Expected message"
  > Command: cd ace-test-runner && bundle exec ace-test-runner --format progress 2>&1 | grep "FAILURES"

- [ ] **Test Format Integration**: Verify all formats work correctly and maintain backward compatibility
  > TEST: Format Compatibility Check
  > Type: Integration Validation
  > Assert: All three formats (progress, progress-file, compact) work correctly
  > Command: cd ace-test-runner && for fmt in progress progress-file compact; do echo "Testing $fmt:"; bundle exec ace-test-runner --format $fmt; done

## Risk Assessment

### Technical Risks
- **Risk:** Minitest output parsing complexity - different minitest versions may have different output formats
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Test against multiple minitest versions, implement fallback to file-level reporting
  - **Rollback:** Revert to existing compact formatter behavior

- **Risk:** Performance impact from per-test execution vs grouped execution
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Benchmark both approaches, document performance trade-offs
  - **Rollback:** Default to per-file execution if performance unacceptable

### Integration Risks
- **Risk:** Breaking changes to existing CLI interface
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Maintain existing default behavior, add format parameter as optional
  - **Monitoring:** Verify existing scripts continue working without format flag

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] **Per-Test Progress Accuracy**: Default format shows 83 dots for 83 tests with only failed tests showing F
- [ ] **Per-File Progress Option**: --format progress-file shows 11 dots for 11 files
- [ ] **Accurate Failure Reporting**: Failures show proper format with file location and message
- [ ] **CLI Format Selection**: --format parameter works with all three options (progress, progress-file, compact)

### Implementation Quality Assurance
- [ ] **Backward Compatibility**: Existing ace-test-runner usage continues to work unchanged
- [ ] **Performance**: Per-file format maintains fast execution, per-test format provides accuracy
- [ ] **Error Handling**: Invalid format values show helpful error message with available options

## Out of Scope

- ❌ **Custom Progress Indicators**: Only using standard ., F, E, S characters
- ❌ **Colored Output**: No ANSI color codes for progress indicators
- ❌ **Progress Bars**: Only dot-based progress, no percentage or visual bars
- ❌ **Real-time Test Names**: No display of current test being executed

## References

- Current ace-test-runner compact formatter implementation
- Existing progress reporting showing 11 dots for 11 files instead of 83 for 83 tests
- Broken failure reporting where all dots show F instead of specific failed tests
- Intentional typo in env_parser_test.rb for formatter testing
- TestExecutor per_file execution option for performance optimization