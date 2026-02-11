---
tc-id: TC-005
title: Create Second Task Worktree
---

## Objective

Verify multiple task worktrees can coexist.

## Steps

1. Create worktree for task 888
   ```bash
   ace-git-worktree create --task 888 --no-push --no-pr --no-commit --no-auto-navigate
   ```

2. List all task-associated worktrees
   ```bash
   ace-git-worktree list --task-associated --format table
   ```

3. Verify both tasks have worktrees
   ```bash
   ace-git-worktree list --task-associated --format json | grep -c '"task":'
   ```

## Expected

- Exit code: 0
- Both task 999 and 888 have worktrees
- List shows two task-associated worktrees
