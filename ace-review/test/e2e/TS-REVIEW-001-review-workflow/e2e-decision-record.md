# E2E Decision Record - ace-review

Scenario: `TS-REVIEW-001-review-workflow`
Date: 2026-04-12

## Keep
- `TC-001-single-model`
  - Reason: validates full review execution path with real provider call and persisted session artifacts.
- `TC-002-multi-model`
  - Reason: validates multi-model and reviewers-format orchestration with real execution outputs.

## Remove
- `TC-001-help-survey`
  - Reason: CLI help/discovery behavior is deterministic and low-cost in fast tests/docs.
- `TC-002-preset-discovery`
  - Reason: preset discovery behavior is covered deterministically by preset/config tests.
- `TC-003-preset-composition`
  - Reason: dry-run composition behavior overlaps deterministic preset manager coverage.
- `TC-004-subject-processing`
  - Reason: subject parsing/processing is deterministic and covered by molecule tests.
- `TC-005-error-handling`
  - Reason: dry-run validation and configuration errors are deterministic CLI contracts.

## Deterministic Coverage Backfill
- Migrated deterministic test layers into:
  - `test/fast/*`
  - `test/feat/*`
- Recorded deterministic files under `unit-coverage-reviewed` in `scenario.yml`.
