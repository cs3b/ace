## E2E Change Plan: ace-test-runner

**Generated:** 2026-03-20 22:50 WET  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/a-review-improve-ace-test-runner/e2e-review.md`  
**Scope:** `TS-TEST-001-test-execution`, `TS-TEST-002-suite-execution`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 2 | 2 | 0 |
| Test Cases | 5 | 5 | 0 |

### REMOVE (0 TCs)

None.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| TS-TEST-001 / TC-002-run-specific-file | Valuable file-scope behavior with explicit command/report artifact evidence |
| TS-TEST-001 / TC-003-run-test-group | Valuable group-scope behavior not redundant with TC-002 |

### MODIFY (3 TCs)

| TC | Change Needed |
|----|---------------|
| TS-TEST-001 / TC-001-run-package-tests.verify.md | Require explicit report artifact checks (report listing/capture evidence) in addition to exit code and summary |
| TS-TEST-002 / TC-001-run-full-suite.verify.md | Tighten expectation from generic multi-package mention to explicit suite/group execution and captured exit evidence |
| TS-TEST-002 / TC-002-verify-failure-propagation.verify.md | Tighten non-zero propagation checks and require explicit failure indicator evidence |

### CONSOLIDATE (0 TCs)

None.

### ADD (0 new TCs)

None.

### Proposed Scenario Structure

`TS-TEST-001-test-execution/` (3 TCs)
- TC-001: package test run (tightened verifier)
- TC-002: specific file run (unchanged)
- TC-003: test group run (unchanged)

`TS-TEST-002-suite-execution/` (2 TCs)
- TC-001: full suite execution (tightened verifier)
- TC-002: failure propagation (tightened verifier)

### Next Steps

1. Apply verifier updates for the 3 MODIFY targets.
2. Keep runner/scenario structure unchanged unless verification reveals command/evidence drift.
3. Run `mise exec -- ace-test ace-test-runner`.
