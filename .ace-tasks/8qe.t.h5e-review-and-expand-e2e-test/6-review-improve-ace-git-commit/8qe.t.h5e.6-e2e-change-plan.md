## E2E Change Plan: ace-git-commit

**Generated:** 2026-03-18
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/6-review-improve-ace-git-commit/8qe.t.h5e.6-e2e-review.md`
**Scope:** package-wide

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 6 | 6 | 0 |
| Est. cost/run | medium | medium | 0 |

### REMOVE (0 TCs)

- None.

### KEEP (1 TCs)

| TC | Notes |
|----|-------|
| `TC-001-help-survey` | Keep as lightweight CLI interface smoke check for `--help` contract; retain low-cost discovery signal. |

### MODIFY (5 TCs)

| TC | Change Needed |
|----|---------------|
| `TC-002-basic-commit` | Remove dependency wording on Goal 1; require explicit `-m` usage directly in constraints. |
| `TC-003-dry-run-and-paths` | Remove Goal 1 dependency wording; keep deterministic dry-run + path assertions. |
| `TC-004-delete-and-rename` | Normalize wording and artifact expectations; keep explicit delete and rename+modify validation. |
| `TC-005-auto-split` | Remove Goal 1 dependency wording; keep split behavior checks scoped to package paths. |
| `TC-006-no-split` | Remove Goal 1 dependency wording; keep explicit `--no-split` single-commit assertion. |

### CONSOLIDATE (0 TCs -> 0 TCs)

- None. Current split of behaviors is reasonable and readable.

### ADD (0 TCs)

- None. Existing TCs already cover high-value end-to-end commit pipeline behaviors.

### Cross-Cutting Rewrite Actions

1. Normalize verifier expectation formatting in all `TC-*.verify.md` files (avoid duplicate numbered-list structure).
2. Keep `runner.yml.md` / `verifier.yml.md` bundle lists unchanged but update runner-level guidance to remove Goal 1 coupling language.
3. Keep `scenario.yml` metadata stable; no scenario split required.

### Proposed Scenario Structure

`TS-COMMIT-001-commit-workflow/` (6 TCs)
- `TC-001`: help survey smoke
- `TC-002`: basic commit
- `TC-003`: dry-run + path handling
- `TC-004`: delete + rename
- `TC-005`: auto-split
- `TC-006`: no-split override

### Confirmation

Plan approved for immediate Stage 3 rewrite in this assignment context.
