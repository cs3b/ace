## E2E Change Plan: ace-git-secrets

Generated: 2026-03-18
Based on: `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/5-review-improve-ace-git-secrets/e2e-review.md`
Scope: package-wide

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 7 | 8 | +1 |

### REMOVE (0 TCs)

None.

### KEEP (7 TCs)

- TC-001..TC-007 retained; no removals in this cycle to avoid churn while expanding release-gate coverage.

### MODIFY (3 artifacts)

- `scenario.yml`: add sandbox artifact bucket for TC-008.
- `runner.yml.md`: include TC-008 runner and update goal count text.
- `verifier.yml.md`: include TC-008 verifier.

### CONSOLIDATE (0)

None in this cycle.

### ADD (1 new TC)

- `TC-008-check-release-gate`
  - Validates `check-release` failure behavior on known secret history.
  - Verifies JSON format payload shape (`passed`, `message`, `token_count`, `tokens`).
  - Verifies strict mode invocation returns non-success and emits release-gate messaging.

### Proposed Scenario Structure

`TS-SECRETS-001-secrets-workflow/` (8 TCs)
- TC-001: help survey
- TC-002: secret detection
- TC-003: history persistence
- TC-004: output and filtering
- TC-005: rewrite workflow
- TC-006: error handling
- TC-007: config cascade
- TC-008: check-release gate

### Execution Notes

- Keep existing naming conventions and standalone runner/verify pair model.
- Preserve scenario setup ownership in `scenario.yml`; no setup logic in TC runner files.
