## E2E Change Plan: ace-docs

**Generated:** 2026-03-20 23:35 WET  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/d-review-improve-ace-docs-e2e/e2e-review.md`  
**Scope:** `TS-DOCS-001-docs-operations`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 3 | 4 | +1 |

### REMOVE (0 TCs)

None.

### KEEP (0 TCs)

None (all existing TCs are modified for stricter evidence capture).

### MODIFY (3 TCs)

| TC | Change Needed |
|----|---------------|
| TC-001-discover-docs.runner.md / .verify.md | Standardize explicit discover artifact capture (`discover.stdout/.stderr/.exit`) and require seeded corpus evidence |
| TC-002-validate-docs.runner.md / .verify.md | Standardize explicit validate artifact capture and tighten verifier to require concrete validation-result evidence |
| TC-003-status-check.runner.md / .verify.md | Standardize explicit status artifact capture and tighten verifier summary expectations |

### CONSOLIDATE (0 TCs)

None.

### ADD (1 new TCs)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| TC-004-update-docs | TS-DOCS-001-docs-operations | Real CLI-driven frontmatter update behavior with before/after artifact evidence |

### Proposed Scenario Structure

`TS-DOCS-001-docs-operations/` (4 TCs)
- TC-001: discover docs (artifact naming tightened)
- TC-002: validate docs (artifact naming + evidence tightened)
- TC-003: status check (artifact naming + summary evidence tightened)
- TC-004: update docs (new CLI mutation coverage)

### Next Steps

1. Apply scenario + bundle include updates for TC-004.
2. Apply runner/verifier rewrites for TC-001..TC-003.
3. Add TC-004 runner/verifier files.
4. Run `mise exec -- ace-test ace-docs`.
