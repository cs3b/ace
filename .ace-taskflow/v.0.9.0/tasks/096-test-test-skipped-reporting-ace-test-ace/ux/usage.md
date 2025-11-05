# Skipped Test Reporting - Usage Documentation

## Overview

This feature enhances test reporting to provide clear visibility of skipped tests in console output, making it easy for developers to:
- Track test coverage gaps at a glance
- Identify disabled/pending tests quickly
- Monitor test suite health across packages
- Make informed decisions about enabling skipped tests

## What Changed

### Individual Test Runs (ace-test)

**Before:**
```bash
$ ace-test

...S..F..S...

Details: test-reports/20250923-232039/
✅ 12 tests, 24 assertions, 1 failures, 0 errors (1.23s)
```

**After:**
```bash
$ ace-test

...S..F..S...

Details: test-reports/20250923-232039/
⚠️ 12 tests, 24 assertions, 1 failures, 0 errors, 2 skipped (1.23s)
```

**Key Changes:**
- Skipped count now appears in summary line when > 0
- Status icon changes from ✅ to ⚠️ when tests are skipped (informational, not alarming)
- 'S' dots during execution remain visible (cyan color)

### Multi-Package Suite (ace-test-suite)

**Before:**
```bash
$ ace-test-suite

═════════════════════════════════════════════════════════════════
✅ ALL TESTS PASSED

Packages:  8/8 passed, 0 failed
Tests:     157/157 passed, 0 failed
Assertions: 324/324 passed, 0 failed
Duration:  12.45s (wall time)
═════════════════════════════════════════════════════════════════
```

**After:**
```bash
$ ace-test-suite

═════════════════════════════════════════════════════════════════
⚠️ ALL TESTS PASSED (with 5 skipped)

Packages:  8/8 passed, 0 failed
Tests:     157 total, 152 passed, 0 failed, 5 skipped
Assertions: 324/324 passed, 0 failed
Duration:  12.45s (wall time)

Packages with skips:
  ace-test-runner: 3 skipped
  ace-core: 2 skipped
═════════════════════════════════════════════════════════════════
```

**Key Changes:**
- Overall status shows "(with N skipped)" when skips exist
- Tests line now shows: "total, passed, failed, skipped"
- New section lists packages with skip counts
- Status icon changes to ⚠️ for informational awareness

### Package Table (ace-test-suite detailed view)

**Before:**
```
| Package | Status | Tests | Passed | Failed | Duration |
|---------|--------|-------|--------|--------|----------|
| ace-core | ✅ Pass | 45 | 43 | 2 | 2.31s |
```

**After:**
```
| Package | Status | Tests | Passed | Failed | Skipped | Duration |
|---------|--------|-------|--------|--------|---------|----------|
| ace-core | ✅ Pass | 45 | 43 | 0 | 2 | 2.31s |
```

**Key Changes:**
- New "Skipped" column added between "Failed" and "Duration"
- Shows skip count per package for easy tracking

## Usage Scenarios

### Scenario 1: Running tests with no skips (common case)

**Command:**
```bash
$ ace-test
```

**Output:**
```bash
.................

Details: test-reports/20251105-103045/
✅ 17 tests, 42 assertions, 0 failures, 0 errors (0.45s)
```

**Behavior:** Clean output, no mention of skipped tests. Status icon remains ✅ for success.

---

### Scenario 2: Running tests with some skips (typical development)

**Command:**
```bash
$ ace-test
```

**Output:**
```bash
...S..F..S...

Details: test-reports/20251105-103045/
⚠️ 12 tests, 24 assertions, 1 failures, 0 errors, 2 skipped (1.23s)

FAILURES (1):
  test/atoms/parser_test.rb:42 - Expected "value", got nil
  → Details: test-reports/20251105-103045/failures/001-test_parse_config.md
```

**Behavior:**
- Skipped count (2) shown in summary
- Status icon changed to ⚠️ to indicate informational status
- Failures still displayed as before
- Easy to see both test issues and coverage gaps

---

### Scenario 3: Running suite with mixed skip distribution

**Command:**
```bash
$ ace-test-suite
```

**Output:**
```bash
═════════════════════════════════════════════════════════════════
  ACE Test Suite Runner - Running 8 packages
═════════════════════════════════════════════════════════════════

[ace-core]          ✅ 45 tests, 98 assertions, 0 failures                2.31s
[ace-context]       ✅ 23 tests, 56 assertions, 0 failures                1.12s
[ace-test-runner]   ⚠️ 52 tests, 104 assertions, 0 failures, 3 skipped   3.45s
[ace-docs]          ⚠️ 37 tests, 82 assertions, 0 failures, 2 skipped    2.01s
...

═════════════════════════════════════════════════════════════════
⚠️ ALL TESTS PASSED (with 5 skipped)

Packages:  8/8 passed, 0 failed
Tests:     157 total, 152 passed, 0 failed, 5 skipped
Assertions: 324/324 passed, 0 failed
Duration:  12.45s (wall time)

Packages with skips:
  ace-test-runner: 3 skipped
  ace-docs: 2 skipped
═════════════════════════════════════════════════════════════════
```

**Behavior:**
- Per-package display shows skip counts with ⚠️ icon
- Aggregate summary includes total skipped (5)
- New section lists which packages have skips
- Easy to identify packages needing attention

---

### Scenario 4: All tests skipped (edge case)

**Command:**
```bash
$ ace-test
```

**Output:**
```bash
SSSSSSSSSS

Details: test-reports/20251105-103045/
⚠️ 10 tests, 0 assertions, 0 failures, 0 errors, 10 skipped (0.01s)
```

**Behavior:**
- Clear indication that all tests were skipped
- Status icon ⚠️ signals informational status
- Fast execution time typical of skipped tests
- No failures section since nothing actually ran

---

### Scenario 5: High skip rate in suite (>20%)

**Command:**
```bash
$ ace-test-suite
```

**Output:**
```bash
═════════════════════════════════════════════════════════════════
⚠️ ALL TESTS PASSED (with 45 skipped)

Packages:  8/8 passed, 0 failed
Tests:     157 total, 112 passed, 0 failed, 45 skipped
Assertions: 224/224 passed, 0 failed
Duration:  8.23s (wall time)

Packages with skips:
  ace-test-runner: 25 skipped
  ace-docs: 15 skipped
  ace-core: 5 skipped
═════════════════════════════════════════════════════════════════
```

**Behavior:**
- High skip count (28% of tests) clearly visible
- Easy to identify which packages contribute most skips
- Agent reporter will flag this as actionable in automated reports
- Developers can prioritize which packages to investigate

## JSON/Markdown Reports

### JSON Output (already working, verified for consistency)

```bash
$ ace-test --format json
```

**Output:**
```json
{
  "status": "success",
  "stats": {
    "total": 12,
    "passed": 10,
    "failed": 0,
    "errors": 0,
    "skipped": 2,
    "assertions": 24,
    "duration": 1.23
  },
  "failures": []
}
```

**Note:** JSON output already includes `skipped` field. This implementation verifies consistency with console output.

### Markdown Reports (already working, verified for consistency)

Markdown reports in `test-reports/latest/report.md` already include skipped in the metrics table:

```markdown
## Test Metrics

| Metric | Value |
|--------|-------|
| Total Tests | 12 |
| Passed | 10 |
| Failed | 0 |
| Errors | 0 |
| Skipped | 2 |
| Assertions | 24 |
| Duration | 1.23s |
```

**Note:** Markdown reports already include skipped. This implementation ensures console matches markdown.

## Agent Integration

### Agent Reporter Output (already working, verified for consistency)

When using `--format agent`, skipped tests appear as actionable items:

```
ACTIONABLE_FAILURES:
  (none)

ACTIONABLE_ITEMS:
  - REVIEW_SKIPS: 2 skipped tests need review
    Priority: info
    Action: Review and enable skipped tests

NEXT_STEPS:
  - Review skipped tests and enable if possible
  - Consider adding documentation for permanently skipped tests
```

**Note:** Agent reporter already surfaces skips. This implementation ensures visibility in all output formats.

## Configuration

No configuration changes required. The feature works automatically:
- Shows skipped count when > 0
- Uses informational icon (⚠️) for non-alarming presentation
- Integrates seamlessly with existing output formats

## Backward Compatibility

- Existing JSON/markdown reports continue to work unchanged
- Console output enhanced without breaking CI/CD parsers
- Status codes unchanged (skips don't cause failure)
- All existing test assertions remain valid

## Tips and Best Practices

**When you see skipped tests:**
1. Review why tests are skipped (pending features, platform-specific, etc.)
2. Add documentation comments explaining permanent skips
3. Consider enabling skipped tests if the feature is now available
4. Monitor skip rates to ensure test coverage doesn't degrade

**For CI/CD:**
- Skipped tests don't cause build failures (informational only)
- JSON output includes skipped for parsing
- Track skip trends over time to monitor test health

**For development:**
- Use skip counts to identify incomplete test coverage
- Prioritize enabling skipped tests during feature development
- Use suite view to find packages with high skip rates
