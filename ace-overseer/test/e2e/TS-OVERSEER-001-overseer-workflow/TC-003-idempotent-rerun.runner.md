# Goal 3 -- Idempotent Re-Run

## Goal

Run `ace-overseer work-on --task 8pp.t.q7w` a second time (after Goal 2 created the worktree). Verify the command reuses existing orchestration resources rather than creating duplicates.

## Workspace

Save all output to `results/tc/03/`. Capture:

- The command's stdout, stderr, and exit code
- Worktree list output after re-run
- `ace-overseer status --format json` output after re-run
- Optional tmux listing as supporting evidence (`tmux list-windows -t "$ACE_TMUX_SESSION"`)

## Constraints

- This goal depends on Goal 2 having already created resources for task 8pp.t.q7w.
- Use public-state artifacts (`ace-git-worktree list`, `ace-overseer status --format json`) as primary oracle.
- Do not depend on task-window naming conventions (for example `t.q7w`) for pass/fail.
- All artifacts must come from real tool execution, not fabricated.
