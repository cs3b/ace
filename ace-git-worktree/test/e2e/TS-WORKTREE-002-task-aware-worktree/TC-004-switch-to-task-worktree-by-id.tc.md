---
tc-id: TC-004
title: Switch to Task Worktree by Task ID
---

## Objective

Verify switching by task ID returns correct path.

## Steps

1. Get worktree path by task ID
   ```bash
   TASK_PATH=$(ace-git-worktree switch 999)
   echo "Task worktree path: $TASK_PATH"
   ```

2. Verify path exists and contains task files
   ```bash
   TASK_PATH=$(ace-git-worktree switch 999)
   test -d "$TASK_PATH" && echo "Path exists - PASS"
   test -d "$TASK_PATH/.ace-taskflow" && echo "Taskflow dir exists - PASS"
   ```

## Expected

- Exit code: 0
- Returns path to task 999's worktree
- Path contains .ace-taskflow directory
