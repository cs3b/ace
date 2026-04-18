# Goal 3 — Switch and Output Formats

## Goal

Use `switch` to resolve a created worktree path, then run `list` in table, JSON, and simple formats. Keep this goal focused on usable output: switch path must resolve, JSON must parse, and table/simple output must remain human-usable.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/switch.stdout`, `.stderr`, `.exit` — switch command output (path to worktree)
- `results/tc/03/list-table.stdout`, `.stderr`, `.exit` — list in table format
- `results/tc/03/list-json.stdout`, `.stderr`, `.exit` — list in JSON format
- `results/tc/03/list-simple.stdout`, `.stderr`, `.exit` — list in simple format

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree switch feature/test-worktree`
  2. `ace-git-worktree list`
  3. `ace-git-worktree list --format json`
  4. `ace-git-worktree list --format simple`
- Worktrees from Goal 2 must still exist for this goal to work.
- All artifacts must come from real tool execution, not fabricated.
