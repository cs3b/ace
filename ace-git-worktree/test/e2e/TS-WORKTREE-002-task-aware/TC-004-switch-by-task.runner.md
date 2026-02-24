# Goal 4 — Switch by Task ID

## Goal

Switch to task 999's worktree using the task ID (not the branch name). Verify the returned path is correct and points to a valid worktree directory containing the project's taskflow files (.ace-taskflow directory).

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/switch-task.stdout`, `.stderr`, `.exit` — switch by task ID output
- `results/tc/04/path-check.txt` — verification that the returned path exists and contains expected files
- `results/tc/04/taskflow-check.txt` — listing of .ace-taskflow directory in the worktree

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree switch targeting task 999.
- Verify the returned path is a real directory with the expected project structure.
- All artifacts must come from real tool execution, not fabricated.
