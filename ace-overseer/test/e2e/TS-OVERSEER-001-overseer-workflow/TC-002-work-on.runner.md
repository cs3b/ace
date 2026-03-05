# Goal 2 — Work-On Happy Path

## Goal

Use `ace-overseer work-on` with task 8pp.t.q7w to create a worktree, open a tmux window, and initialize an assignment using the default preset. Verify all three resources are created.

## Workspace

Save all output to `results/tc/02/`. Capture:
- The command's stdout, stderr, and exit code
- Worktree verification (ace-git-worktree list showing task 8pp.t.q7w)
- Tmux verification (tmux list showing window for task)
- Assignment verification (ace-overseer status --format json showing task 8pp.t.q7w assignment state)
- `results/tc/02/overseer-status.json` — machine-readable overseer status output
- `results/tc/02/overseer-status.exit` and `results/tc/02/overseer-status.stderr`

## Constraints

- The sandbox has task 8pp.t.q7w in .ace-tasks/ and default preset in .ace/assign/presets/.
- Using what you learned from Goal 1, invoke ace-overseer work-on.
- When verifying tmux windows, target `ACE_TMUX_SESSION` explicitly (for example `tmux list-windows -t "$ACE_TMUX_SESSION"`).
- Verify assignment activation via `ace-overseer status --format json` (cross-worktree oracle), not root-scoped `ace-assign status`.
- All artifacts must come from real tool execution, not fabricated.
