---
tc-id: TC-001
title: Create Worktree for Task (Dry Run)
---

## Objective

Verify task-aware worktree creation shows correct plan in dry-run mode.

## Steps

1. Run task worktree creation with dry-run
   ```bash
   ace-git-worktree create --task 999 --dry-run --no-push --no-pr --no-commit
   ```

## Expected

- Exit code: 0
- Output shows planned branch name (includes task ID)
- Output shows planned worktree path
- No actual worktree created
