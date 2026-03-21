## E2E Change Plan: ace-idea

**Generated:** 2026-03-20
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/e-review-improve-ace-idea-e2e/e2e-review.md`
**Scope:** `TS-IDEA-001`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 3 | 4 | +1 |
| Est. cost/run | low | low-medium | +1 TC |

### REMOVE (0 TCs)

- None.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| `TC-001-create-idea` | Keeps core creation + persisted frontmatter evidence |
| `TC-003-move-idea` | Keeps root-scope transition and ID reuse checks |

### MODIFY (3 files / 1 TC behavior adjustment)

| Target | Change Needed |
|--------|---------------|
| `TC-002-list-ideas.runner.md` | Correct `--in next` expectation wording and add explicit capture artifacts |
| `TC-002-list-ideas.verify.md` | Align FAIL text with root-scope inclusion semantics |
| `scenario.yml` | Add `results/tc/04` sandbox layout entry and archive mention in E2E justification |

### CONSOLIDATE (0)

- None.

### ADD (1 new TC)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| `TC-004-archive-idea` | `TS-IDEA-001` | `ace-idea update --move-to archive` creates archive-scoped placement and `ace-idea list --in archive` exposes the idea |

### Proposed Scenario Structure

`TS-IDEA-001-idea-lifecycle/` (4 TCs)
- `TC-001-create-idea`
- `TC-002-list-ideas`
- `TC-003-move-idea`
- `TC-004-archive-idea` (new)

Shared updates:
- Include TC-004 in `runner.yml.md` bundle list.
- Include TC-004 in `verifier.yml.md` bundle list.
- Update verifier final summary format from `X/3` to `X/4`.

### Approval Decision

Approved for execution: KEEP existing lifecycle flow, fix TC-002 contract mismatch, and add archive-transition coverage with TC-004.

### Next Step

Execute rewrite by applying the file changes above, then run package verification with `mise exec -- ace-test ace-idea`.
