---
tc-id: TC-007
title: Remove Task Worktree by Task ID
---

## Objective

Verify task worktree removal using --task flag.

## Steps

1. Remove task 888's worktree
   ```bash
   ace-git-worktree remove --task 888
   ```

2. Verify removal
   ```bash
   ace-git-worktree list --task-associated | grep -v 888 && echo "Task 888 removed - PASS"
   ```

3. Verify task 999 still exists
   ```bash
   ace-git-worktree list --task-associated | grep 999 && echo "Task 999 still exists - PASS"
   ```

## Expected

- Exit code: 0
- Task 888 worktree removed
- Task 999 worktree unaffected
