## E2E Rewrite Summary: ace-git-commit

**Executed:** 2026-03-18
**Plan:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/6-review-improve-ace-git-commit/8qe.t.h5e.6-e2e-change-plan.md`
**Mode:** execute

### Changes Applied

| Action | Count | Details |
|--------|-------|---------|
| Deleted | 0 TCs | none |
| Created | 0 TCs | none |
| Modified | 11 files | runner guidance + TC runner/verifier normalization |
| Consolidated | 0 -> 0 TCs | none |
| Kept | 6 TCs | test inventory unchanged |

### Files Changed

**Modified:**
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/runner.yml.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-002-basic-commit.runner.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-003-dry-run-and-paths.runner.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-005-auto-split.runner.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-006-no-split.runner.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-001-help-survey.verify.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-002-basic-commit.verify.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-003-dry-run-and-paths.verify.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-004-delete-and-rename.verify.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-005-auto-split.verify.md`
- `ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-006-no-split.verify.md`

### Final State

| Metric | Before | After |
|--------|--------|-------|
| Scenarios | 1 | 1 |
| Test Cases | 6 | 6 |

### Verification

- [x] Scenario count matches plan
- [x] TC count matches plan
- [x] No stale Goal-1 dependency references in modified runners
- [x] Package tests pass: `mise exec -- ace-test ace-git-commit`

Test result snapshot:
- `248 tests, 531 assertions, 0 failures, 0 errors`

