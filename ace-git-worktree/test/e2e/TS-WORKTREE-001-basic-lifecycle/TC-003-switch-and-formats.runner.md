# Goal 3 — Switch and Output Formats

## Goal

Use the switch command to get the path of a worktree created in Goal 2. Then test the list command with different output formats: table, JSON, and simple. Verify that switch returns a valid path, JSON output is parseable, table output has headers, and simple output is compact.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/switch.stdout`, `.stderr`, `.exit` — switch command output (path to worktree)
- `results/tc/03/list-table.stdout`, `.stderr`, `.exit` — list in table format
- `results/tc/03/list-json.stdout`, `.stderr`, `.exit` — list in JSON format
- `results/tc/03/list-simple.stdout`, `.stderr`, `.exit` — list in simple format

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree switch and list with format options.
- Worktrees from Goal 2 must still exist for this goal to work.
- All artifacts must come from real tool execution, not fabricated.
