# E2E Lifecycle Summary - ace-bundle (8qe.t.h5e.7)

## Coverage Matrix

| Feature / Behavior | Unit Coverage | E2E Coverage Before | Decision |
|---|---|---|---|
| CLI surface discovery (`--help`) | command tests exist | TC-001 | KEEP |
| Preset loading and section rendering | unit + integration coverage present | TC-002 | KEEP |
| File pattern resolution | unit coverage present | TC-003 | KEEP |
| Output routing (threshold + explicit `--output`) | integration coverage exists but CLI routing remains E2E-critical | TC-004 + TC-005 | CONSOLIDATE |
| CLI success/error path parity | integration coverage exists, CLI artifact contract is E2E-specific | TC-006 | MODIFY (reindex to TC-005) |

## Change Plan

### KEEP
- TC-001 help survey
- TC-002 preset loading
- TC-003 file patterns

### MODIFY
- TC-004: broadened from threshold-only to consolidated threshold + explicit override routing checks
- TC-006 -> TC-005: reindexed parity case after consolidation
- `scenario.yml`: sandbox-layout updated to 5 TC structure
- `runner.yml.md` and `verifier.yml.md`: TC list updated to 5-case suite

### REMOVE
- TC-005 output-override (superseded by consolidated TC-004)

### CONSOLIDATE
- Source: TC-004 (auto-format) + TC-005 (output-override)
- Target: TC-004 (expanded output-routing coverage)

### ADD
- None

## Rewrite Summary

- Scenarios: 1 -> 1
- Test cases: 6 -> 5
- Deleted: 2 files (`TC-005-output-override.runner.md`, `TC-005-output-override.verify.md`)
- Renamed: 2 files (`TC-006-cli-api-parity.*` -> `TC-005-cli-api-parity.*`)
- Modified: scenario + runner/verifier manifests + consolidated TC-004 + reindexed TC-005 parity files

## Verification

- Command: `mise exec -- ace-test ace-bundle`
- Result: pass (`312 tests, 877 assertions, 0 failures, 0 errors, 1 skipped`)
- Report: `.ace-local/test/reports/bundle/8qhztx/`
