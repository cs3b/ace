---
tc-id: TC-003
title: Abort on Prompt
---

## Objective

Verify that running `ace-overseer prune` without `--yes` and answering "n" aborts without removing anything.

## Steps

1. Run prune with "n" answer
   ```bash
   OUTPUT=$(echo "n" | ace-overseer prune 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify output shows abort message
   ```bash
   echo "$OUTPUT" | grep -qi "abort" && echo "PASS: Abort message shown" || echo "FAIL: No abort message"
   ```

3. Verify worktrees are untouched
   ```bash
   echo "n" | ace-overseer prune >/dev/null 2>&1
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "$WORKTREE_LIST" | grep -q "001" && echo "PASS: Task 001 worktree still exists after abort" || echo "FAIL: Task 001 worktree removed despite abort!"
   echo "$WORKTREE_LIST" | grep -q "002" && echo "PASS: Task 002 worktree still exists after abort" || echo "FAIL: Task 002 worktree removed despite abort!"
   ```

## Expected

- Output contains abort message
- Both worktrees remain after abort
- No side effects
