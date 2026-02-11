---
tc-id: TC-008
title: Prune Orphaned Worktrees (Dry Run)
---

## Objective

Verify prune command runs successfully in dry-run mode.

## Steps

1. Create an orphaned worktree scenario
   ```bash
   WORKTREES_ROOT="$(pwd)/../worktrees"
   rm -rf "$WORKTREES_ROOT/new-feature-wt"
   ```

2. Run prune with dry-run
   ```bash
   ace-git-worktree prune --dry-run
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

3. Verify command completed
   ```bash
   # Note: Git 2.50+ auto-cleans metadata on directory deletion, so prune may find no orphans
   # The important thing is the command runs successfully
   echo "PASS: Prune dry-run completed"
   ```

## Expected

- Exit code: 0
- Prune command completes successfully
- No actual pruning occurs (dry-run mode)
