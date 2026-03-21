## E2E Change Plan: ace-support-nav

**Generated:** 2026-03-19 00:16 WET  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/9-review-improve-ace-support-nav/e2e-review.md`  
**Scope:** `TS-NAV-001-resource-navigation`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 5 | 5 | 0 |

### REMOVE (0 TCs)

None.

### KEEP (3 TCs)

| TC | Notes |
|----|-------|
| TC-001-help-survey | Keeps high-level tool discovery context for subsequent goals |
| TC-002-extension-inference | Core inference chain behavior remains valid |
| TC-003-priority-and-exact-match | Core priority behavior remains valid |

### MODIFY (3 TCs)

| TC | Change Needed |
|----|---------------|
| TC-001-help-survey.runner.md / .verify.md | Extend Goal 1 to capture and validate `ace-nav sources` output so command-surface coverage grows without adding a new TC |
| TC-004-error-handling.verify.md | Require explicit missing resource identifier evidence + keep no-stack-trace guarantee |
| TC-005-cross-protocol.verify.md | Strengthen consistency check wording to require explicit `.wf.md` evidence and tie back to shorthand behavior |

### CONSOLIDATE (0 TCs)

None.

### ADD (0 new TCs)

None.

### Proposed Scenario Structure

`TS-NAV-001-resource-navigation/` (5 TCs)
- TC-001: help survey
- TC-002: extension inference chain
- TC-003: inference priority and exact match
- TC-004: missing-resource error handling (tightened verification)
- TC-005: cross-protocol inference (tightened verification)

### Next Steps

1. Apply scenario/runner/verifier updates for TC-001.
2. Tighten TC-004/TC-005 verifier expectations.
3. Run `mise exec -- ace-test ace-support-nav`.
