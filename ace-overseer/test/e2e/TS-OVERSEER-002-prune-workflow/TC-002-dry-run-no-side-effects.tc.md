---
tc-id: TC-002
title: Dry-Run Does Not Remove Worktrees
---

## Objective

Verify that dry-run mode does not actually remove any worktrees — both task 001 and task 002 worktrees should still exist after dry-run.

## Steps

1. Run dry-run and verify both worktrees still exist
   ```bash
   ace-overseer prune --dry-run >/dev/null 2>&1

   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "Worktree list after dry-run:"
   echo "$WORKTREE_LIST"

   echo "$WORKTREE_LIST" | grep -q "001" && echo "PASS: Task 001 worktree still exists" || echo "FAIL: Task 001 worktree was removed by dry-run!"
   echo "$WORKTREE_LIST" | grep -q "002" && echo "PASS: Task 002 worktree still exists" || echo "FAIL: Task 002 worktree was removed by dry-run!"
   ```

## Expected

- Both worktrees present after dry-run
- No side effects from dry-run
