---
tc-id: TC-002
title: Create Worktree for Task
---

## Objective

Verify worktree creation for a task ID creates correct structure.

## Steps

1. Create worktree for task 999
   ```bash
   ace-git-worktree create --task 999 --no-push --no-pr --no-commit --no-auto-navigate
   ```

2. Verify worktree was created
   ```bash
   ace-git-worktree list --show-tasks
   ```

3. Check branch name contains task ID
   ```bash
   ace-git-worktree list --format json | grep -o '"branch":"[^"]*999[^"]*"'
   ```

## Expected

- Exit code: 0
- Worktree created with branch containing task ID "999"
- Worktree appears in list with task association
- Branch name follows convention (e.g., 999-test-feature-implementation)
