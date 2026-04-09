---
id: 8pkgym
title: E2E Test Fixes (Suite 8pke6qc)
type: conversation-analysis
tags: []
created_at: '2026-02-21 11:18:27'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pkgym-e2e-test-fixes.md"
---

# Reflection: E2E Test Fixes (Suite 8pke6qc)

**Date**: 2026-02-21
**Context**: Fixing 9 failing E2E tests across ace-assign, ace-git-worktree, ace-overseer, and ace-git-commit
**Author**: agent
**Type**: Conversation Analysis

## What Went Well

- Plan-driven approach made the work systematic — pre-categorized failures (A=code bug, B=test issue, C=runner infra) meant no time wasted on root cause discovery
- Experience reports from the test runner (`.cache/ace-test-e2e/*/experience.r.md`) were very actionable — they described root causes clearly and saved investigation time
- Background task execution (running tests while working on other fixes) improved throughput significantly
- Reading worktree_remover.rb code path carefully revealed the `ignore_untracked` logic gap before running tests — the `has_uncommitted_changes?` correctly ignored untracked files but `remove_git_worktree` wasn't getting `--force`, so git still rejected the removal
- Unit tests (112 for ace-overseer, 14 for worktree_remover) passed after code changes, giving confidence before e2e re-runs

## What Could Be Improved

- **Iterative failures**: TC-001 in TS-ASSIGN-003d still failed after the CACHE_BASE fix — the ISO8601 regex didn't account for YAML-quoted timestamps. A closer read of the TC file before fixing would have caught this in one pass
- **TC-004 in TS-OVERSEER-001**: Required a second fix (idempotency in TmuxWindowOpener) because the original analysis only diagnosed the "no window created" case, not the "duplicate window on re-run" case
- **Implicit tmux behavior**: The `automatic-rename` tmux feature caused TC-003 to pass but left a subtle trap — window renamed from "task.001" to "fish" right after creation, making it invisible to a subsequent `list-windows` check. Adding `automatic-rename: "off"` to the fixture preset was the fix but it required understanding the entire tmux preset cascade

## Key Learnings

- **YAML timestamp quoting**: `ace-assign` stores timestamps with quotes in YAML (e.g., `'2026-02-21T11:10:30Z'`). Regex patterns matching ISO8601 dates must account for surrounding single-quotes: `^['\"]?[0-9]{4}-...`
- **`git worktree remove` vs `--force`**: Even when `has_uncommitted_changes?` is run with `--untracked-files=no` and returns false (no tracked changes), `git worktree remove` will still refuse removal if untracked files exist unless `--force` is passed. The Ruby layer and git layer have different definitions of "clean"
- **tmux `automatic-rename` default**: tmux renames windows to the active process name after creation. Window presets must explicitly set `automatic-rename: "off"` to preserve the intended window name. Without this, `list-windows` returns the process name ("fish"), not the worktree basename
- **ace-tmux preset cascade**: Presets are resolved from `.ace/tmux/windows/` → `~/.ace/tmux/windows/` → gem `.ace-defaults/tmux/windows/`. E2E fixtures can inject a minimal preset by providing `.ace/tmux/config.yml` (defaults.window) and `.ace/tmux/windows/task.yml`
- **Test status progression**: `ace-overseer work-on` changes task status from `pending` → `in-progress`. Sed patterns in setup scripts that target `status: pending` silently fail when status has already advanced. Pattern should be `s/status: [a-z_-]*/status: done/` or similar
- **Worktree paths and sandbox boundaries**: Paths like `$(pwd)/../worktrees` escape the e2e sandbox directory. All worktree paths in test cases must stay within `$(pwd)/` to avoid path validation rejection and sandbox contamination

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Multi-pass fix cycles**: TC-001 in TS-ASSIGN-003d and TC-004 in TS-OVERSEER-001 each required two fix iterations because the initial analysis was incomplete.
  - Occurrences: 2 test cases
  - Impact: Extra test runs (each ~90s) and additional context switching
  - Root Cause: The experience reports were accurate but didn't enumerate all edge cases (e.g., re-run idempotency for TC-004, YAML quoting for TC-001)

- **Implicit env behavior (tmux auto-rename)**: The tmux window name changed immediately after creation, making the idempotency check unreliable until `automatic-rename: "off"` was added.
  - Occurrences: Affected TC-003 and TC-004
  - Impact: Required deep dive into ace-tmux preset system and options application order
  - Root Cause: tmux's default auto-rename behavior is easy to overlook when testing window creation

#### Medium Impact Issues

- **git worktree --force semantics**: The `ignore_untracked` feature in WorktreeRemover had a logic gap — the Ruby-level check passed but the git-level command still rejected the removal.
  - Occurrences: TC-004 in TS-OVERSEER-002
  - Impact: Required code change after test failure + re-run cycle
  - Root Cause: The original code comment described the intent correctly but the implementation was incomplete (passed `force: force` but not `force: force || ignore_untracked`)

#### Low Impact Issues

- **Output text mismatch**: TC-001 in TS-OVERSEER-002 expected "safely pruned" but actual output was "can be pruned" (no "safely").
  - Occurrences: 1 test case
  - Impact: Minor — test definition fix only, not a behavioral issue

### Improvement Proposals

#### Process Improvements

- When fixing a test case, read the full TC file before fixing (not just the experience report summary) — this would have caught the YAML-quoting regex issue in TC-002 of TS-ASSIGN-003d
- For idempotency-sensitive tests (TCs that call the same command twice), explicitly check if the tool's second invocation behavior is covered

#### Tool Enhancements

- `ace-overseer work-on` could log the status transition (e.g., "Task 001: pending → in-progress") to make it easier to trace why sed patterns fail in setup scripts
- `WorktreeRemover` could add a comment or guard making it explicit that `ignore_untracked: true` implies `--force` on the git command

#### Communication Protocols

- Experience reports from the test runner are high-value — the workflow of "read experience.r.md first, then plan fixes" worked well and should be the standard approach

## Action Items

### Stop Doing

- Using hardcoded sed patterns like `s/status: pending/status: done/` — prefer flexible patterns that match any status value

### Continue Doing

- Reading experience reports before diving into fixes — they provide accurate root cause analysis
- Running unit tests after code changes before e2e re-runs — caught regressions early
- Categorizing failures before fixing (code bug vs test issue vs infra) — saved time

### Start Doing

- When a test case involves a second invocation of the same tool, explicitly verify idempotency behavior before declaring a fix complete
- Add `automatic-rename: "off"` as standard practice in any tmux window preset used in e2e fixtures

## Technical Details

**Files changed:**
- `ace-assign/test-e2e/scenarios/TS-ASSIGN-003d-display-audit/scenario.yml` — CACHE_BASE fix
- `ace-assign/test-e2e/scenarios/TS-ASSIGN-003d-display-audit/TC-002-audit-trail-verification.tc.md` — ISO8601 regex with YAML quote support
- `ace-overseer/test-e2e/scenarios/TS-OVERSEER-002-prune-workflow/scenario.yml` — flexible sed status pattern
- `ace-overseer/test-e2e/scenarios/TS-OVERSEER-002-prune-workflow/TC-001-dry-run-lists-candidates.tc.md` — output text match fix
- `ace-overseer/test-e2e/scenarios/TS-OVERSEER-001-work-on-workflow/fixtures/.ace/tmux/config.yml` — new: defaults.window: task
- `ace-overseer/test-e2e/scenarios/TS-OVERSEER-001-work-on-workflow/fixtures/.ace/tmux/windows/task.yml` — new: minimal preset with automatic-rename off
- `ace-overseer/lib/ace/overseer/molecules/tmux_window_opener.rb` — idempotency via window_already_open? check
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_remover.rb` — pass --force when ignore_untracked
- 6 TC files in `TS-WORKTREE-001`: `$(pwd)/../worktrees` → `$(pwd)/worktrees`

**Commits (6 total):**
1. `96439ec8f` fix(ace-assign): correct CACHE_BASE path in TS-ASSIGN-003d scenario
2. `3381303bc` fix(ace-git-worktree): use sandbox-local path for worktrees in TS-WORKTREE-001
3. `c154d8e1b` fix(ace-overseer): fix tmux window and task status issues in e2e tests
4. `344c58e4a` fix(ace-assign): fix ISO8601 regex to handle quoted YAML values in TC-002
5. `331b6899f` fix(ace-overseer): make TmuxWindowOpener idempotent and fix TC-001 output match
6. `9d41eafef` fix(ace-git-worktree): pass --force to git worktree remove when ignore_untracked

## Additional Context

- Test suite run: 8pke6qc (09:27Z), 27 passed / 9 failed initially
- Branch: 273-namespace-workflows-with-domain-prefixes
- b36ts failures were excluded (handled by another agent)
- TS-ASSIGN-006 and TS-COMMIT-004a were Category C (infra fixed by v0.16.8 release) — confirmed passing after re-run