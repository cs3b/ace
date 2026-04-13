## E2E Change Plan: ace-compressor

**Generated:** 2026-04-12
**Based on:** `.ace-tasks/8r9.t.i05-migrate-remaining-packages-to-restarted/3-migrate-ace-compressor-to-restarted/e2e-review-2026-04-12.md`
**Scope:** package-wide

### Recent Change Inventory

Recent package changes affecting E2E confidence:
- `291cd0235` fix compact-refusal smoke fixture content.
- `84d2b0c44` normalize compression/cache behavior in runner paths.
- `0fbc0de7e` parser/cache helper refactors.

Net: no indication that TS-COMP-001 should be removed, but rewrite should refresh scenario metadata and re-verify outputs after fast/feat migration.

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 4 | 4 | 0 |
| Est. cost/run | ~4 TC executions | ~4 TC executions | 0% |

### REMOVE (0 TCs)

No removals proposed. All existing TCs retain smoke-level E2E value.

### Unit Coverage Backfill (0 actions)

No unit backfill required for this cycle.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| `TC-001-help-surface` | Keep as binary command-surface contract check (`--help`, option visibility). |
| `TC-003-per-source-output` | Keep for real filesystem + input-order contract in per-source mode. |

### MODIFY (2 TCs)

| TC | Change Needed |
|----|---------------|
| `TC-002-exact-stdio-and-stats` | Refresh verifier/report wording and evidence references after migration; preserve assertions but ensure they align with post-migration deterministic-layer contract and updated artifacts. |
| `TC-004-compact-refusal` | Retain refusal contract assertions, refresh scenario-level evidence mapping and post-migration verification artifacts after recent compact-path fixes. |

### CONSOLIDATE (0 TCs -> 0 TCs)

No consolidation proposed; each TC covers a distinct smoke behavior.

### ADD (0 new TCs)

No new E2E TCs required in this migration slice.

### Proposed Scenario Structure

`TS-COMP-001-cli-smoke/` (4 TCs)
- `TC-001-help-surface` (KEEP)
- `TC-002-exact-stdio-and-stats` (MODIFY)
- `TC-003-per-source-output` (KEEP)
- `TC-004-compact-refusal` (MODIFY)

Scenario-level rewrite actions:
- Update `scenario.yml` `unit-coverage-reviewed` paths from legacy test layer paths to migrated `test/fast/...` (and `test/feat/...` if any feat tests are introduced).
- Keep E2E-only justification focused on binary wiring, CLI contract, and filesystem side effects.
- Preserve runner/verifier role separation (runner evidence-only, verifier verdict logic).

### Execution Notes for Rewrite Stage

1. Run rewrite and apply approved KEEP/MODIFY decisions.
2. Perform deterministic test migration to `test/fast` (and conditional `test/feat`).
3. Re-run `ace-test-e2e ace-compressor` and confirm all 4 TCs pass with updated references.
4. Ensure no deterministic `*_test.rb` appears under `test/e2e/`.

### Next Steps

- Execute `ace-bundle wfi://e2e/rewrite`.
- Apply the approved changes above while performing package migration.
