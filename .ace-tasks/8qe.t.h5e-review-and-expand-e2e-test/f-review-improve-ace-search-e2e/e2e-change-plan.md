## E2E Change Plan: ace-search

**Generated:** 2026-03-20
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/f-review-improve-ace-search-e2e/e2e-review.md`
**Scope:** `TS-SEARCH-001`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 3 | 4 | +1 |
| Est. cost/run | smoke | smoke+ | +1 TC |

### REMOVE (0 TCs)

- None.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| `TC-001-content-search` | Retains base content-search behavior through real CLI output |
| `TC-002-file-search` | Retains file-mode coverage with deterministic package path |

### MODIFY (8 files / 3 TCs + scenario wiring)

| Target | Change Needed |
|--------|---------------|
| `scenario.yml` | Add `results/tc/04` sandbox layout and include JSON mode in justification |
| `runner.yml.md` | Include new TC-004 runner and update goal order to 1..4 |
| `verifier.yml.md` | Include new TC-004 verifier and update summary format to `X/4` |
| `TC-001-content-search.runner.md` | Add explicit capture artifact contract |
| `TC-001-content-search.verify.md` | Require explicit filename-level evidence references |
| `TC-002-file-search.runner.md` | Add explicit capture artifact contract |
| `TC-002-file-search.verify.md` | Require explicit filename-level evidence references |
| `TC-003-count-mode.runner.md` | Add explicit dual-command capture artifacts |
| `TC-003-count-mode.verify.md` | Require evidence for both files-with-matches and count captures |

### CONSOLIDATE (0)

- None.

### ADD (1 new TC)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| `TC-004-json-output` | `TS-SEARCH-001` | `ace-search --json --type content` emits structured output with match payload evidence |

### Proposed Scenario Structure

`TS-SEARCH-001-search-workflow/` (4 TCs)
- `TC-001-content-search`
- `TC-002-file-search`
- `TC-003-count-mode`
- `TC-004-json-output` (new)

Shared updates:
- Include TC-004 in `runner.yml.md` bundle list.
- Include TC-004 in `verifier.yml.md` bundle list.
- Update verifier final summary format from `X/3` to `X/4`.

### Approval Decision

Approved for execution: retain baseline coverage, tighten evidence contracts, and add JSON output E2E coverage through TC-004.

### Next Step

Execute rewrite by applying the file changes above, then run package verification with `mise exec -- ace-test ace-search`.
