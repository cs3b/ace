---
id: v.0.9.0+task.057
status: in-progress
priority: high
estimate: 8h
dependencies: []
---

# Fix ace-test-runner reporter: Parse failures correctly and generate detailed reports

## Description

The ace-test-runner has a critical bug in test_orchestrator.rb that prevents proper failure reporting:

**Root Cause (Line 67):**
```ruby
if !execution_result[:success] && execution_result[:stderr] && !execution_result[:stderr].empty?
```

This condition treats ANY stderr output (including warnings) as a LoadError, which:
1. Skips parsing stdout entirely
2. Creates fake errors: `errors: test_files.size`
3. Sets `failures: []` - no failure details captured
4. Results in output like "27 tests, 0 failures, 27 errors" with no details

**Example stderr that triggers the bug:**
```
Warning: Could not find task matching 'v.0.9.0+003,v.0.9.0+004'
```

This task fixes the orchestrator to always parse test output and generates complete failure reports.

## Behavioral Specification

### On-Screen Output (Compact)
```bash
💥 94 tests, 712 assertions, 74 failures, 20 errors (2.28s)

ERRORS (7/94) → test-reports/20251001-193807/failures.json:
  test/commands/ideas_command_test.rb:94 - Expected /Statistics/ to match
  → Details: test-reports/20251001-193807/failures/001-test-ideas-statistics.md

  test/commands/ideas_command_test.rb:52 - Expected /v\.0\.9\.0/ to match
  → Details: test-reports/20251001-193807/failures/002-test-list-all-releases.md

  ... (5 more shown)

  ... and 87 more failures. See full report: test-reports/20251001-193807/failures.json
```

### Generated Reports (Complete Details)
```
test-reports/20251001-193807/
├── raw_output.txt              # Complete stdout from Minitest
├── raw_stderr.txt              # Complete stderr (warnings, etc)
├── summary.json                # Quick stats
├── report.json                 # Full report with all data
├── report.md                   # Human-readable summary
├── failures.json               # Array of all 94 failures
└── failures/                   # Individual failure details (limited by config)
    ├── 001-test-ideas-statistics.md
    ├── 002-test-list-all-releases.md
    └── ... (up to max_display from config)
```

### Individual Failure Report Format
```markdown
# Test Error: test_ideas_statistics

**Status:** ERROR
**Location:** test/commands/ideas_command_test.rb:94
**Duration:** 0.02s

## Error Message

Expected /Statistics/ to match "No release found for context: current\n"

## Stack Trace

test/commands/ideas_command_test.rb:94:in 'block (2 levels) in IdeasCommandTest#test_ideas_statistics'
test/commands/ideas_command_test.rb:89:in 'Dir.chdir'
...

## Related stderr

Warning: Could not find task matching 'v.0.9.0+003,v.0.9.0+004'

## Code Context

89:    def test_ideas_statistics
90:      with_test_project do
91:        create_ideas_structure
92:
93:        output = run_command("ideas --statistics")
94:        assert_match /Statistics/, output  # ← ERROR HERE
95:      end
96:    end

## Fix Suggestion

Check the assertion values. Expected and actual don't match.
```

## Acceptance Criteria

### Critical Fixes
- [ ] Orchestrator always parses stdout (doesn't skip on stderr warnings)
- [ ] Parser extracts all failure details: test name, file, line, message, type
- [ ] Summary shows correct counts (e.g., "94 tests, 74 failures, 20 errors")
- [ ] Summary label distinguishes FAILURES vs ERRORS vs "FAILURES & ERRORS"

### Report Generation
- [ ] raw_stderr.txt saved separately in test-reports/
- [ ] failures.json generated with complete failure data (all failures)
- [ ] Individual .md files created (limited to max_display from config)
- [ ] Each .md file includes: message, stack trace, stderr context, code context, fix suggestion
- [ ] Config respected: max_display (default 7) for .md files
- [ ] Config respected: stop_threshold (default 21) for total failures captured

### Output Format
- [ ] On-screen shows up to max_display failures with paths to .md files
- [ ] Relative paths displayed: test/commands/file.rb:94
- [ ] "... and N more" message when failures exceed display limit
- [ ] Works with any formatter (progress, progress-file, json)

### Testing
- [ ] All ace-test-runner tests pass
- [ ] Test against ace-taskflow shows: "94 tests, 74 failures, 20 errors" with details
- [ ] Verify failures.json contains 94 items
- [ ] Verify 7 individual .md files created (or up to config limit)
- [ ] Verify raw_stderr.txt contains warnings

## Implementation Plan

### Planning Steps

* [x] Root cause identified: test_orchestrator.rb:67 skips parsing on stderr
* [x] Confirmed parser works correctly (tested with saved raw_output.txt)
* [x] Confirmed formatter label logic works (FAILURES vs ERRORS)
* [ ] Review existing FailureReportWriter or check if needs creation
* [ ] Review ReportStorage to see how to add raw_stderr.txt saving
* [ ] Confirm config values used: max_display (7) and stop_threshold (21)

### Execution Steps

- [ ] Phase 1: Fix orchestrator to always parse output
  - [ ] In test_orchestrator.rb, change line 67 condition
  - [ ] Only skip parsing if stdout is empty (true LoadError)
  - [ ] Always parse stdout even if stderr has warnings
  - [ ] Remove debug statements added during investigation
  - [ ] Test: Run ace-test on ace-taskflow, confirm parsing works

- [ ] Phase 2: Save stderr separately
  - [ ] In ReportStorage#save_report, add save_stderr() method
  - [ ] Save execution_result[:stderr] to raw_stderr.txt
  - [ ] Update report generation to include stderr path
  - [ ] Test: Verify raw_stderr.txt created with warning content

- [ ] Phase 3: Create/update FailureReportWriter molecule
  - [ ] Check if lib/ace/test_runner/molecules/failure_report_writer.rb exists
  - [ ] If not, create it with write_failure_reports() method
  - [ ] Generate failures/NNN-test-name.md files (limit to max_display)
  - [ ] Include: status, location, message, stack trace, stderr warnings, code context, fix suggestion
  - [ ] Use existing FailureAnalyzer#extract_code_context if available
  - [ ] Test: Generate .md file, verify format and content

- [ ] Phase 4: Associate stderr with failures
  - [ ] Pass stderr to FailureAnalyzer#analyze_all()
  - [ ] Try to match stderr warnings to specific test failures
  - [ ] If can't match, include all stderr in each failure .md
  - [ ] Add stderr_warnings field to TestFailure model
  - [ ] Test: Verify stderr appears in .md files

- [ ] Phase 5: Wire everything in orchestrator
  - [ ] Call FailureReportWriter after report generation
  - [ ] Pass config limits (max_display) to writer
  - [ ] Ensure formatter shows paths to .md files
  - [ ] Test: Full end-to-end with ace-taskflow

- [ ] Phase 6: Verify configuration limits
  - [ ] Confirm max_display (7) limits .md file creation
  - [ ] Confirm stop_threshold (21) used for fail-fast
  - [ ] Update config defaults to match spec if needed
  - [ ] Test: Change config values and verify behavior

- [ ] Testing and validation
  - [ ] Run ace-test-runner test suite - all must pass
  - [ ] Run ace-test on ace-taskflow - expect "94 tests, 74 failures, 20 errors"
  - [ ] Verify failures.json has 94 items
  - [ ] Verify 7 .md files created (or config max_display value)
  - [ ] Verify raw_stderr.txt exists with warnings
  - [ ] Verify on-screen shows correct counts and paths to .md files
  - [ ] Test with different formatters (progress, json)

## Implementation Notes

### Root Cause Analysis (CONFIRMED)

**The Bug (test_orchestrator.rb:67):**
```ruby
if !execution_result[:success] && execution_result[:stderr] && !execution_result[:stderr].empty?
  # Treats ANY stderr as LoadError - SKIPS PARSING!
  @parsed_result = {
    summary: { runs: 0, failures: 0, errors: test_files.size, ... },
    failures: []  # ← NO FAILURE DETAILS!
  }
```

**What Actually Happens:**
1. Tests run successfully but output warnings to stderr: `"Warning: Could not find task..."`
2. Orchestrator sees stderr → thinks it's a LoadError → skips parsing entirely
3. Creates fake result: `errors: test_files.size`, `failures: []`
4. Output shows: "27 tests, 0 failures, 27 errors" with no details
5. But raw_output.txt has correct data: "368 tests, 74 failures, 20 errors"

**Files Involved:**
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb:67` - BUG LOCATION
- `ace-test-runner/lib/ace/test_runner/atoms/result_parser.rb` - Parser (WORKS CORRECTLY)
- `ace-test-runner/lib/ace/test_runner/formatters/progress_formatter.rb` - Display (WORKS CORRECTLY)
- `ace-test-runner/lib/ace/test_runner/molecules/report_storage.rb` - Save reports
- `ace-test-runner/lib/ace/test_runner/molecules/failure_analyzer.rb` - Analyze failures
- `ace-test-runner/lib/ace/test_runner/models/test_failure.rb` - Failure data structure

**What Already Works:**
- ✅ Parser correctly extracts 94 failures from raw_output.txt
- ✅ Formatter correctly shows "FAILURES" vs "ERRORS" label
- ✅ failures.json is generated (when failures_detail exists)
- ✅ Config has max_display (7) and stop_threshold (21)

**What Needs Implementation:**
- ❌ Orchestrator skips parsing on stderr warnings
- ❌ No raw_stderr.txt saved
- ❌ No individual failures/*.md files generated
- ❌ stderr not associated with failures

**Priority:**
Phase 1 (fix orchestrator) is CRITICAL - unblocks everything else.

**Testing Strategy:**
1. Fix orchestrator → verify parsing works with stderr present
2. Test end-to-end with ace-taskflow (94 failures expected)
3. Verify all report files generated correctly
4. Test with different config values
