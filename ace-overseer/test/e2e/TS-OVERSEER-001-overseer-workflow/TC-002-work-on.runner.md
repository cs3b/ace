# Goal 2 -- Work-On Happy Path

## Goal

Run a lightweight CLI surface preflight, then use `ace-overseer work-on --task 8pp.t.q7w` to create a worktree, open a tmux window, and initialize an assignment with the default preset.

## Workspace

Save all output to `results/tc/02/`. Capture:

- `results/tc/02/help-preflight.stdout` from `ace-overseer --help`
- `results/tc/02/help-preflight.stderr` from `ace-overseer --help`
- `results/tc/02/help-preflight.exit` from `ace-overseer --help`
- The work-on command's stdout, stderr, and exit code
- Worktree verification (`ace-git-worktree list` showing task 8pp.t.q7w)
- Tmux verification (`tmux list-windows -t "$ACE_TMUX_SESSION"`)
- Assignment verification in both status modes:

  - `ace-overseer status --format table`
  - `ace-overseer status --format json`

- `results/tc/02/overseer-status.json` -- machine-readable overseer status output
- `results/tc/02/overseer-status-table.stdout`
- `results/tc/02/overseer-status-table.exit` and `results/tc/02/overseer-status-table.stderr`
- `results/tc/02/overseer-status.exit` and `results/tc/02/overseer-status.stderr`

## Constraints

- The sandbox has task 8pp.t.q7w in .ace-tasks/ and default preset in .ace/assign/presets/.
- Preflight should remain minimal: only capture the top-level `ace-overseer --help` output needed for command-surface confirmation.
- Run `ace-overseer work-on --task 8pp.t.q7w` to completion and write `work-on.stdout`, `work-on.stderr`, and `work-on.exit` before starting worktree, tmux, or status verification captures.
- When verifying tmux windows, target `ACE_TMUX_SESSION` explicitly.
- Verify assignment activation via `ace-overseer status --format json` (cross-worktree oracle), not root-scoped `ace-assign status`.
- All artifacts must come from real tool execution, not fabricated.
