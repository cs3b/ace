---
tc-id: TC-004
title: Prune --yes Removes Safe Worktree
---

## Objective

Verify that `ace-overseer prune --yes` removes the safe worktree (task 001) and reports success. This is destructive — TCs 005 and 006 verify post-prune state.

## Steps

1. Run prune with --yes (destructive)
   ```bash
   OUTPUT=$(ace-overseer prune --yes 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify output reports removal of task 001
   ```bash
   echo "$OUTPUT" | grep -q "Removed worktree task\.001" && echo "PASS: Removal message for task 001" || echo "FAIL: No removal message for task 001"
   ```

4. Verify count message
   ```bash
   echo "$OUTPUT" | grep -qE "worktree\(s\) pruned" && echo "PASS: Pruned count message present" || echo "FAIL: Missing pruned count message"
   ```

5. Verify task 001 worktree is gone
   ```bash
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "Worktree list after prune:"
   echo "$WORKTREE_LIST"
   echo "$WORKTREE_LIST" | grep -q "001" && echo "FAIL: Task 001 worktree still exists after prune!" || echo "PASS: Task 001 worktree removed"
   ```

## Expected

- Exit code: 0
- Output shows "Removed worktree task.001"
- Output shows "N worktree(s) pruned."
- Task 001 worktree no longer in `git worktree list`
