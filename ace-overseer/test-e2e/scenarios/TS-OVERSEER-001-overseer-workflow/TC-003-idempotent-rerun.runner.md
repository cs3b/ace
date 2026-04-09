# Goal 3 — Idempotent Re-Run

## Goal

Run `ace-overseer work-on --task 8pp.t.q7w` a second time (after Goal 2 already created the worktree). Verify the command reuses the existing worktree and tmux window rather than creating duplicates.

## Workspace

Save all output to `results/tc/03/`. Capture:
- The command's stdout, stderr, and exit code
- Worktree count for task `8pp.t.q7w` (should be exactly 1)
- Task-window count for `q7w` inside `ACE_TMUX_SESSION` (should be exactly 1)
- Full window listing for diagnostic context

## Constraints

- This goal depends on Goal 2 having already created the worktree.
- When counting tmux windows, target `ACE_TMUX_SESSION` explicitly.
- Count only the task-specific window(s) for `q7w`; do not treat the baseline shell window as a duplicate.
- All artifacts must come from real tool execution, not fabricated.
