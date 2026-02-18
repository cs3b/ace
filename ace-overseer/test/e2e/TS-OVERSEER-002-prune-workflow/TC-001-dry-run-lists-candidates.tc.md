---
tc-id: TC-001
title: Dry-Run Lists Safe and Unsafe Candidates
---

## Objective

Verify that `ace-overseer prune --dry-run` correctly identifies task 001 as safe to prune, does NOT list task 002 as safe, and makes no destructive changes.

## Steps

1. Run prune in dry-run mode
   ```bash
   OUTPUT=$(ace-overseer prune --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify output lists task 001 as safe candidate
   ```bash
   echo "$OUTPUT" | grep -q "task\.001" && echo "PASS: Task 001 listed as candidate" || echo "FAIL: Task 001 not listed"
   ```

4. Verify output shows candidates header
   ```bash
   echo "$OUTPUT" | grep -q "Candidates for cleanup" && echo "PASS: Dry-run header present" || echo "FAIL: Missing dry-run header"
   ```

5. Verify count message
   ```bash
   echo "$OUTPUT" | grep -qE "worktree\(s\) can be safely pruned" && echo "PASS: Count message present" || echo "FAIL: Missing count message"
   ```

6. Verify dry-run has no side effects
   ```bash
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "Worktree list after dry-run:"
   echo "$WORKTREE_LIST"
   echo "$WORKTREE_LIST" | grep -q "001" && echo "PASS: Task 001 worktree still exists" || echo "FAIL: Task 001 worktree was removed by dry-run"
   echo "$WORKTREE_LIST" | grep -q "002" && echo "PASS: Task 002 worktree still exists" || echo "FAIL: Task 002 worktree was removed by dry-run"
   ```

## Expected

- Exit code: 0
- Output shows "Candidates for cleanup:" with task.001 listed
- Output shows count of worktrees that can be safely pruned
- Task 002 should NOT appear as a safe candidate (pending task, active assignment)
- Both worktrees still exist after dry-run
