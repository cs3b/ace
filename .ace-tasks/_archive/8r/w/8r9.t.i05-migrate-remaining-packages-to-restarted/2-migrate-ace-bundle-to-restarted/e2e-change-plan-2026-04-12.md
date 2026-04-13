## E2E Change Plan: ace-bundle
**Generated:** 2026-04-12
**Based on:** .ace-tasks/8r9.t.i05-migrate-remaining-packages-to-restarted/2-migrate-ace-bundle-to-restarted/e2e-review-2026-04-12.md
**Scope:** package-wide

### Impact Summary
| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 5 | 5 | 0 |
| Est. cost/run | baseline | baseline | 0% |

### REMOVE (0 TCs)
None.

### Unit Coverage Backfill (0 actions)
None.

### KEEP (5 TCs)
| TC | Notes |
|----|-------|
| TC-001-help-survey | Keeps real CLI help/interface smoke check and artifact contract. |
| TC-002-preset-loading | Keeps section-vs-simple preset loading through real CLI + filesystem. |
| TC-003-file-patterns | Keeps real glob include/exclude behavior against fixture tree. |
| TC-004-auto-format | Keeps threshold and explicit output routing checks through real binary. |
| TC-005-cli-api-parity | Keeps success/error path CLI behavior verification and diagnostics checks. |

### MODIFY (0 TCs)
None.

### CONSOLIDATE (0 TCs -> 0 TCs)
None.

### ADD (0 new TCs)
None.

### Proposed Scenario Structure
TS-BUNDLE-001-bundle-workflow/ (5 TCs)
- TC-001-help-survey
- TC-002-preset-loading
- TC-003-file-patterns
- TC-004-auto-format
- TC-005-cli-api-parity

### Next Steps
- Execute Stage 3 rewrite as a structural no-op for E2E case files (all KEEP).
- Continue deterministic migration by moving legacy `test/integration/` to `test/feat/` and ATOM/flat suites into `test/fast/`.
