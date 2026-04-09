---
id: 8pkg3z
title: E2E Test Fixes — ace-b36ts Scenario ID Mismatch
type: conversation-analysis
tags: []
created_at: '2026-02-21 10:44:24'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pkg3z-e2e-test-fixes-b36ts-scenario-ids.md"
---

# Reflection: E2E Test Fixes — ace-b36ts Scenario ID Mismatch

**Date**: 2026-02-21
**Context**: Fixed three failing E2E tests (TS-B36TS-002, 003, 004) caused by stale `test-id` values in `scenario.yml` files
**Author**: claude-sonnet-4-6
**Type**: Conversation Analysis

## What Went Well

- The pre-prepared plan accurately identified the root cause without requiring any additional investigation
- Three parallel file edits were efficient — all changes applied in a single tool call batch
- `--dry-run` verification confirmed scenario loading before spending LLM tokens on full test execution
- All 9 test cases (3 per suite) passed on the first attempt after the fix
- The fix was minimal and surgical: 3 one-line changes across 3 files, no collateral changes

## What Could Be Improved

- `ace-test-e2e` produces no visible terminal output — results are silently written to `.cache/ace-test-e2e/` directories, requiring manual discovery of report paths
- The naming inconsistency (`TS-TIMESTAMP-00X` vs `TS-B36TS-00X`) should ideally be caught at test-creation time, not discovered via runtime failures
- No linter or pre-commit check validates that `test-id` in `scenario.yml` matches the containing directory name

## Key Learnings

- E2E `test-id` must exactly match the directory-embedded ID prefix — a mismatch causes `status: error` with 0 test cases executed (the runner errors before TC execution)
- `ace-test-e2e` output is in `.cache/ace-test-e2e/<run-id>-<pkg>-<ts>-reports/summary.r.md` — not on stdout
- `--dry-run` is a fast, zero-cost way to validate scenario.yml parsing before committing to a full LLM-backed test run
- When all TC slots show 0 executed (0 passed, 0 failed, 0 total), the failure is almost certainly in scenario loading, not test logic

## Action Items

### Stop Doing

- Assuming E2E test-id values are correct when creating or copying scenario.yml templates — always verify the ID matches the directory

### Continue Doing

- Using `--dry-run` as a first verification step before full E2E runs
- Parallel file edits for independent, structurally identical changes
- Reading cached `summary.r.md` reports directly rather than trying to capture stdout from `ace-test-e2e`

### Start Doing

- Consider adding a validation step (or linter rule) that checks `test-id` in `scenario.yml` matches the directory name prefix
- When creating new E2E test directories, immediately verify the test-id with `ace-test-e2e <pkg> <id> --dry-run` before writing test cases

## Technical Details

Files modified:
- `ace-b36ts/test-e2e/scenarios/TS-B36TS-002-cli-configuration-and-defaults/scenario.yml`: `TS-TIMESTAMP-002` → `TS-B36TS-002`
- `ace-b36ts/test-e2e/scenarios/TS-B36TS-003-hierarchical-split-format/scenario.yml`: `TS-TIMESTAMP-003` → `TS-B36TS-003`
- `ace-b36ts/test-e2e/scenarios/TS-B36TS-004-cli-integration/scenario.yml`: `TS-TIMESTAMP-004` → `TS-B36TS-004`

Result: 9/9 test cases pass across all three suites.

## Additional Context

- TS-B36TS-001 was unaffected (already had correct `test-id: TS-B36TS-001`)
- Category B bug (test definition wrong), not Category A (application bug) or Category C (test case logic wrong)