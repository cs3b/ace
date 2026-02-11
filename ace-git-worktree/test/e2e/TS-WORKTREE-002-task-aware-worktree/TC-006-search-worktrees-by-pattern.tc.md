---
tc-id: TC-006
title: Search Worktrees by Pattern
---

## Objective

Verify search filter works with task branch names.

## Steps

1. Search for worktrees containing "999"
   ```bash
   ace-git-worktree list --search 999
   ```

2. Search for worktrees containing "test"
   ```bash
   ace-git-worktree list --search test
   ```

## Expected

- Search "999": Returns only task 999 worktree
- Search "test": Returns both task worktrees (both have "test" in name)
