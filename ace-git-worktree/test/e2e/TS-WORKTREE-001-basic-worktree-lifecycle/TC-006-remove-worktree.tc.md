---
tc-id: TC-006
title: Remove Worktree
---

## Objective

Verify worktree removal works correctly.

## Steps

1. Confirm the worktree exists
   ```bash
   ace-git-worktree list | grep feature/test-worktree
   ```

2. Remove the feature worktree
   ```bash
   ace-git-worktree remove feature/test-worktree
   ```

3. Verify worktree was removed
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   test ! -d "$WORKTREES_ROOT/feature-wt" && echo "Directory removed - PASS"
   ace-git-worktree list | grep -v feature/test-worktree && echo "Not in list - PASS"
   ```

## Expected

- Exit code: 0
- Worktree directory removed
- No longer appears in worktree list
