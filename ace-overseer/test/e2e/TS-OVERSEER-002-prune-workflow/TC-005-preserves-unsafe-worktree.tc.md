---
tc-id: TC-005
title: Prune Preserves Unsafe Worktree
---

## Objective

Verify that after prune, the unsafe worktree (task 002) is still present — the safety checker prevented its removal.

## Steps

1. Verify task 002 worktree still exists
   ```bash
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "Worktree list:"
   echo "$WORKTREE_LIST"
   echo "$WORKTREE_LIST" | grep -q "002" && echo "PASS: Task 002 worktree preserved (unsafe)" || echo "FAIL: Task 002 worktree was removed!"
   ```

2. Verify no safe candidates remain after prune
   ```bash
   OUTPUT=$(ace-overseer prune --dry-run 2>&1)
   echo "$OUTPUT"
   echo "$OUTPUT" | grep -qE "0 worktree|no .* candidates|(none)" && echo "PASS: No safe candidates remaining" || echo "INFO: Some candidates still listed"
   ```

## Expected

- Task 002 worktree still present in `git worktree list`
- Follow-up dry-run shows no safe candidates (task 001 already pruned, task 002 still unsafe)
