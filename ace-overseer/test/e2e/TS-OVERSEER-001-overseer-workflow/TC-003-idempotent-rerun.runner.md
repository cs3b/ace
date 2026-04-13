# Goal 3 -- Idempotent Re-Run

## Goal

Run `ace-overseer work-on --task 8pp.t.q7w` a second time (after Goal 2 already created the worktree). Verify the command reuses the existing worktree and tmux window rather than creating duplicates.

## Workspace

Save all output to `results/tc/03/`. Capture:

- The command's stdout, stderr, and exit code
- Worktree count for task 8pp.t.q7w (should be exactly 1)
- Task-window count for `t.q7w` inside `ACE_TMUX_SESSION` (should be exactly 1), even if the session has other non-task windows

## Constraints

- This goal depends on Goal 2 having already created the worktree.
- When counting tmux windows, target `ACE_TMUX_SESSION` explicitly (for example `tmux list-windows -t "$ACE_TMUX_SESSION"`), then count only windows whose names include `t.q7w`.
- All artifacts must come from real tool execution, not fabricated.
