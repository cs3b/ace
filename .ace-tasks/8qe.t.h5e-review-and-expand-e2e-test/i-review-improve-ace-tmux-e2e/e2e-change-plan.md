## E2E Change Plan: ace-tmux

**Generated:** 2026-03-21 00:30 WET  
**Based on:** `.ace-tasks/8qe.t.h5e-review-and-expand-e2e-test/i-review-improve-ace-tmux-e2e/e2e-review.md`  
**Scope:** `TS-TMUX-001-tmux-management`

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | 1 | 1 | 0 |
| Test Cases | 2 | 3 | +1 |

### REMOVE (0 TCs)

None.

### Unit Coverage Backfill (0 actions)

None.

### KEEP (0 TCs)

None.

### MODIFY (2 TCs)

| TC | Change Needed |
|----|---------------|
| TC-001-list-presets.runner.md / .verify.md | Strengthen preset-discovery evidence requirements (explicit selected preset artifact and explicit empty-state handling) |
| TC-002-start-session.runner.md / .verify.md | Tighten success/failure path evidence to require explicit `tmux ls` capture and explicit constrained-failure wording |

### CONSOLIDATE (0 TCs -> 0 TCs)

None.

### ADD (1 new TCs)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| TC-003-add-window.runner.md / .verify.md | TS-TMUX-001-tmux-management | Real `ace-tmux window` execution path against an existing session, with artifact-backed outcome |

### Proposed Scenario Structure

`TS-TMUX-001-tmux-management/` (3 TCs)
- TC-001: list presets and capture selected preset handoff
- TC-002: start detached session and verify via `tmux ls`
- TC-003: add window to existing session and verify via window/session evidence

### Next Steps

1. Apply runner/verifier rewrites for TC-001 and TC-002.
2. Add TC-003 runner/verify pair and update scenario/runner/verifier bundles.
3. Run `mise exec -- ace-test ace-tmux` for package-scoped verification.
