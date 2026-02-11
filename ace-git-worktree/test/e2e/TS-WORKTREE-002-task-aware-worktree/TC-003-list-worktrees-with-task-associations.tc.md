---
tc-id: TC-003
title: List Worktrees with Task Associations
---

## Objective

Verify list --show-tasks displays task information.

## Steps

1. List worktrees with task info
   ```bash
   ace-git-worktree list --show-tasks
   ```

2. Verify task-associated filter works
   ```bash
   ace-git-worktree list --task-associated
   ```

3. Verify non-task filter works
   ```bash
   ace-git-worktree list --no-task-associated
   ```

## Expected

- --show-tasks: Shows task ID alongside worktree info
- --task-associated: Shows only task-linked worktrees
- --no-task-associated: Shows only non-task worktrees (main)
