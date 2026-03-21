## E2E Change Plan: ace-llm

**Generated:** 2026-03-21 00:00 WET  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/h-review-improve-ace-llm-e2e/e2e-review.md`  
**Scope:** `TS-LLM-001-llm-query`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 2 | 3 | +1 |

### REMOVE (0 TCs)

None.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| TC-001-basic-query | Core live-query behavior coverage remains valuable |
| TC-002-model-selection | Core provider/model routing + format behavior coverage remains valuable |

### MODIFY (2 TCs)

| TC | Change Needed |
|----|---------------|
| TC-001-basic-query.verify.md | Require explicit stdout/stderr/exit evidence and clear success-or-auth-failure outcome mapping |
| TC-002-model-selection.verify.md | Tighten routing/format evidence requirements; preserve explicit early-failure evidence allowance |

### CONSOLIDATE (0 TCs)

None.

### ADD (1 new TC)

| TC | Purpose |
|----|---------|
| TC-003-unknown-provider | Validate deterministic CLI routing failure for unsupported provider alias/model prefix |

### Proposed Scenario Structure

`TS-LLM-001-llm-query/` (3 TCs)
- TC-001: basic query
- TC-002: model selection
- TC-003: unknown provider routing error

### Next Steps

1. Add TC-003 runner/verifier pair and update scenario/runner/verifier indexes.
2. Tighten TC-001 and TC-002 verifier requirements.
3. Run `mise exec -- ace-test ace-llm` and record verification in task report.
