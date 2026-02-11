---
tc-id: TC-009
title: Prune Cleanup
---

## Objective

Verify prune command cleans up orphaned entries.

## Steps

1. Run prune to clean up
   ```bash
   ace-git-worktree prune
   ```

2. Verify cleanup
   ```bash
   ace-git-worktree list
   # Orphaned entry should be removed from list
   ```

## Expected

- Exit code: 0
- Orphaned worktree entry removed from git metadata
- List shows only valid worktrees
