---
id: v.0.9.0+task.096
status: draft
priority: medium
estimate: 4-6h
dependencies: []
---

# Add skipped test reporting to ace-test and ace-test-suite summaries

## Behavioral Specification

### User Experience

**Current State - What Users See:**
- Individual test runs (ace-test): Console shows "✅ 12 tests, 24 assertions, 1 failures, 0 errors (1.23s)"
  - Skipped tests are displayed as cyan 'S' dots during execution
  - BUT skipped count is NOT shown in the summary line (even when skips exist)
- Multi-package suite (ace-test-suite): Shows "Tests: 57/57 passed, 0 failed"
  - No skipped count displayed anywhere in suite output
  - Even when tests are skipped, the count appears as if all tests ran

**Problem:**
Users cannot easily see how many tests were skipped, making it difficult to:
- Track test coverage gaps
- Identify disabled/pending tests
- Monitor test suite health across packages

**Desired State - What Users Should See:**
- Individual test runs: "⚠️ 12 tests, 24 assertions, 1 failures, 0 errors, 2 skipped (1.23s)"
  - Clear visibility of skipped count in summary
  - Non-alarming presentation (informational, not a failure)
- Multi-package suite: "Tests: 62 total, 57 passed, 0 failed, 5 skipped"
  - Total test count includes skipped
  - Per-package breakdown shows skip counts
  - Aggregate summary shows total skips across all packages

### Expected Behavior

**For Individual Test Runs (ace-test):**
1. When tests are skipped (count > 0):
   - Console summary line includes skipped count
   - Status icon may change to ⚠️ to indicate informational status
   - Skipped tests remain visible as 'S' dots during execution
2. When no tests are skipped (count = 0):
   - Summary remains clean without mentioning skipped
   - OR optionally shows "0 skipped" for consistency

**For Multi-Package Suite (ace-test-suite):**
1. Aggregate skipped counts across all packages
2. Display per-package skip counts in package table
3. Show total skipped in overall summary
4. Identify packages with high skip rates (>20% skipped)

**For All Output Formats:**
- Markdown reports: Already include skipped column (verify consistency)
- JSON output: Already includes skipped count (verify consistency)
- Agent reports: Already surfaces skips as actionable items (verify consistency)

### Interface Contract

**Console Output Format (Individual Runs):**

```bash
# ace-test (with skips)
...S..F..S...

Details: test-reports/20250923-232039/
⚠️ 12 tests, 24 assertions, 1 failures, 0 errors, 2 skipped (1.23s)

# Current behavior: No skipped count shown
# Expected behavior: Skipped count visible in summary
```

**Suite Summary Format:**

```bash
# ace-test-suite (multi-package)
═════════════════════════════════════════════════════════════════
⚠️ ALL TESTS PASSED (with 5 skipped)

Packages:  8/8 passed, 0 failed
Tests:     157 total, 152 passed, 0 failed, 5 skipped
Assertions: 324/324 passed, 0 failed
Duration:  12.45s (wall time)

Package Skips:
  ace-test-runner: 3 skipped
  ace-core: 2 skipped
═════════════════════════════════════════════════════════════════

# Current behavior: Shows "157/157 passed" (skips hidden)
# Expected behavior: Shows actual totals with skip breakdown
```

**Package Table Format:**

```
| Package | Status | Tests | Passed | Failed | Skipped | Duration |
|---------|--------|-------|--------|--------|---------|----------|
| ace-core | ✅ Pass | 45 | 43 | 0 | 2 | 2.31s |

# Current: No Skipped column
# Expected: Skipped column added
```

**Error Handling:**
- Missing skip data: Treat as 0 skipped (backward compatibility)
- Invalid skip count: Log warning, display as "?" or 0
- Format errors: Gracefully degrade to current behavior

**Edge Cases:**
- All tests skipped: Show ⚠️ status with clear message
- High skip rate (>20%): Highlight in agent report as actionable
- Zero tests run: Skip count should be N/A or 0

### Success Criteria

- [ ] **Console Visibility**: Skipped count appears in individual test run console summary when > 0
- [ ] **Suite Aggregation**: Suite summary shows total skipped count aggregated across all packages
- [ ] **Per-Package Display**: Suite output shows skipped count for each package
- [ ] **Non-Intrusive Design**: Skipped tests displayed as informational (⚠️ or ℹ️), not alarming (❌)
- [ ] **Markdown Consistency**: Markdown reports include skipped column (verify existing implementation)
- [ ] **JSON Consistency**: JSON output includes skipped count (verify existing implementation)
- [ ] **Backward Compatibility**: Existing reports without skips display correctly

### Validation Questions

- [ ] **Display Preference**: Should skipped count show "0 skipped" when no skips exist, or only appear when > 0?
- [ ] **Icon Selection**: Which icon best represents skipped tests: ⚠️ (warning), ℹ️ (info), or other?
- [ ] **Detail Section**: Should there be a "SKIPPED (N):" section listing individual skipped tests (similar to failures)?
- [ ] **High Skip Threshold**: What percentage of skipped tests should trigger agent warnings? (Currently >20%)
- [ ] **Suite Display Priority**: Should packages with skips be highlighted or sorted differently in suite output?

## Objective

**User Value:**
Provide clear visibility into skipped tests across both individual gem test runs and multi-package suite executions, enabling developers to:
- Monitor test coverage gaps
- Identify disabled/pending tests quickly
- Track test health across the mono-repo
- Make informed decisions about enabling skipped tests

**Technical Context:**
The infrastructure for tracking skipped tests already exists:
- Minitest reports skipped tests
- `ResultParser` extracts skip counts
- `TestResult` model stores skip data
- Markdown/JSON outputs include skipped

This is purely a UX enhancement to surface existing data more prominently in console output.

## Scope of Work

### Behavioral Scope

**Included - User-Facing Changes:**
1. **Individual Test Console Output**
   - Update summary line format to include skipped count
   - Conditional display (only when > 0, or always show)
   - Icon adjustment if status includes skips
2. **Suite Aggregation**
   - Calculate total_skipped across all packages
   - Track per-package skip counts
3. **Suite Display**
   - Show aggregate skipped in overall summary
   - Display skipped column in package table
   - Optionally list packages with skips
4. **Verification**
   - Confirm markdown reports work correctly
   - Confirm JSON output includes skipped
   - Confirm agent reports handle skips appropriately

### Deliverables

#### Behavioral Specifications
- Console summary format with skipped count
- Suite summary format with aggregate and per-package skips
- Package table format with skipped column

#### Validation Artifacts
- Test scenarios covering:
  - No skipped tests (0 skips)
  - Some skipped tests (1-20% skip rate)
  - Many skipped tests (>20% skip rate)
  - All tests skipped (100% skip rate)
- Multi-package scenarios with varying skip distributions

## Out of Scope

- ❌ **Detailed Skip Reasons**: Extracting and displaying WHY tests were skipped (Minitest skip messages)
- ❌ **Skip Rate Thresholds**: Configurable thresholds for warning about high skip rates
- ❌ **Historical Skip Tracking**: Comparing skip counts across test runs over time
- ❌ **Framework Changes**: Modifying Minitest integration or parsing logic
- ❌ **Agent Report Enhancements**: Major changes to agent report format (minor updates OK)
- ❌ **Interactive Skip Management**: Commands to enable/disable skipped tests

## Technical Notes

### Current Implementation Status

**Already Working:**
- Minitest reports: "X runs, Y assertions, Z failures, A errors, B skips"
- `ResultParser` extracts skip count from Minitest output
- `TestResult` model stores `skipped` attribute
- `TestResult#has_skips?` method exists
- Markdown reports include skipped in metrics table
- JSON output includes skipped count
- Agent reporter creates actionable items for skips

**Files Requiring Changes:**
1. `ace-test-runner/lib/ace/test_runner/formatters/progress_formatter.rb:46-48`
   - Update console summary line to include skipped
2. `ace-test-runner/lib/ace/test_runner/suite/result_aggregator.rb:31-43`
   - Add `total_skipped` to aggregation hash
3. `ace-test-runner/lib/ace/test_runner/suite/display_manager.rb:78-110, 129-134`
   - Show skipped in per-package and overall summaries

### Data Flow
```
Minitest Output → ResultParser → TestResult (skipped tracked)
                                      ↓
                          Formatters (NEEDS UPDATE)
                                      ↓
                          Console/Report Output
                                      ↓
                          ResultAggregator (NEEDS UPDATE)
                                      ↓
                          Suite Summary (NEEDS UPDATE)
```

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251008-005102-improve-the-test-summary-add-test-skipped-for-a.md`
- ace-test-runner gem: `/Users/mc/Ps/ace-meta/ace-test-runner/`
- Minitest documentation: https://github.com/seattlerb/minitest
- Related: Agent reporter already surfaces skips (`ace-test-runner/lib/ace/test_runner/organisms/agent_reporter.rb:140-147`)
