## E2E Rewrite Summary: ace-compressor

**Executed:** 2026-04-12
**Plan:** `.ace-tasks/8r9.t.i05-migrate-remaining-packages-to-restarted/3-migrate-ace-compressor-to-restarted/e2e-change-plan-2026-04-12.md`
**Mode:** execute

### Changes Applied

| Action | Count | Details |
|--------|-------|---------|
| Deleted | 0 TCs | none |
| Created | 0 TCs | none |
| Modified | 2 TCs | `TC-002-exact-stdio-and-stats`, `TC-004-compact-refusal` verifier updates |
| Consolidated | 0 -> 0 TCs | none |
| Kept | 2 TCs | `TC-001-help-surface`, `TC-003-per-source-output` |

### Files Changed

**Modified:**
- `ace-compressor/test/e2e/TS-COMP-001-cli-smoke/scenario.yml`
- `ace-compressor/test/e2e/TS-COMP-001-cli-smoke/e2e-decision-record.md`
- `ace-compressor/test/e2e/TS-COMP-001-cli-smoke/TC-002-exact-stdio-and-stats.verify.md`
- `ace-compressor/test/e2e/TS-COMP-001-cli-smoke/TC-004-compact-refusal.verify.md`

### Final State

| Metric | Before | After |
|--------|--------|-------|
| Scenarios | 1 | 1 |
| Test Cases | 4 | 4 |

### Verification

- [x] Scenario count matches plan
- [x] TC count matches plan
- [x] No stale references to legacy deterministic test paths in package E2E files
- [x] All scenarios have 2-5 TCs
- [x] Modified/kept TCs include command output + exit artifacts

### Execution Evidence

- `ace-test-e2e ace-compressor` -> PASS 4/4
- Latest report: `.ace-local/test-e2e/8rb0kk4-compressor-ts001-reports`

### Notes

- Scenario setup was hardened to avoid sandbox warning when `mise.toml` is absent (`cp` now guarded by file-existence check).
- Deterministic suite migration to `test/fast/` was applied in parallel with rewrite to keep scenario `unit-coverage-reviewed` references current.
