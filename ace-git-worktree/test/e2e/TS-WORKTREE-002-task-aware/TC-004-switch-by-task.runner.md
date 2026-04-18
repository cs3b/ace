# Goal 4 — Switch by Task ID

## Goal

Switch to task 8pp.t.q7w's worktree using the task ID (not the branch name). Verify the returned path is correct and points to a valid worktree directory containing the project's task files in .ace-tasks/.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/switch-task.stdout`, `.stderr`, `.exit` — switch by task ID output
- `results/tc/04/path-check.txt` — verification that the returned path exists and contains expected files

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree switch 8pp.t.q7w`
  2. `ace-git-worktree switch --list`
- Verify the returned path is a real directory with the expected project structure.
- All artifacts must come from real tool execution, not fabricated.
