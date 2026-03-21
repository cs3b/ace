## E2E Change Plan: ace-prompt-prep

**Generated:** 2026-03-20  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/g-review-improve-ace-prompt-prep/e2e-review.md`  
**Scope:** `TS-PREP-001`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 3 | 4 | +1 |
| Est. cost/run | smoke | smoke+ | +1 TC |

### REMOVE (0 TCs)

- None.

### KEEP (2 TCs)

| TC | Notes |
|----|-------|
| `TC-002-setup-workspace` | Keeps real setup behavior and workspace creation assertions |
| `TC-003-process-and-archive` | Keeps core archive and symlink behavior through real CLI |

### MODIFY (7 files / 2 existing TCs + scenario wiring + goal 1 tightening)

| Target | Change Needed |
|--------|---------------|
| `scenario.yml` | Add `results/tc/04` sandbox layout and update justification text for context-mode coverage |
| `runner.yml.md` | Include new TC-004 runner and update goal order to 1..4 |
| `verifier.yml.md` | Include new TC-004 verifier and update summary format to `X/4` |
| `TC-001-help-survey.runner.md` | Add explicit artifact capture names (`help.stdout`, `help.stderr`, `help.exit`) |
| `TC-001-help-survey.verify.md` | Require concrete filename evidence in verdict |
| `TC-002-setup-workspace.runner.md` | Add explicit setup capture filenames and expected artifact set |
| `TC-003-process-and-archive.runner.md` | Add explicit process/archive/symlink/content capture filenames |

### CONSOLIDATE (0)

- None.

### ADD (1 new TC)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| `TC-004-bundle-context` | `TS-PREP-001` | Context-enabled processing path (`--bundle`) emits observable context-expanded output and still archives prompt |

### Proposed Scenario Structure

`TS-PREP-001-prompt-processing/` (4 TCs)
- `TC-001-help-survey`
- `TC-002-setup-workspace`
- `TC-003-process-and-archive`
- `TC-004-bundle-context` (new)

Shared updates:
- Include TC-004 in `runner.yml.md` bundle list.
- Include TC-004 in `verifier.yml.md` bundle list.
- Update verifier final summary format from `X/3` to `X/4`.

### Approval Decision

Approved for execution: retain baseline behavior checks, tighten artifact evidence contracts, and add deterministic context-mode E2E coverage.

### Next Step

Execute rewrite by applying the file changes above, then run package verification with `mise exec -- ace-test ace-prompt-prep`.
