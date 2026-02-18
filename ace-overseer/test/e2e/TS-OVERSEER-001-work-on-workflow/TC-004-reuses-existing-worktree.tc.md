---
tc-id: TC-004
title: Idempotent Re-run Reuses Existing Worktree
---

## Objective

Verify that running `ace-overseer work-on --task 001` a second time reuses the existing worktree and tmux window rather than creating duplicates.

## Steps

1. Run work-on for task 001 again (already created in TC-003)
   ```bash
   OUTPUT=$(ace-overseer work-on --task 001 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify only one worktree for task 001 (no duplicate)
   ```bash
   WORKTREE_COUNT=$(git worktree list | grep -c "001")
   [ "$WORKTREE_COUNT" -eq 1 ] && echo "PASS: Exactly 1 worktree for task 001" || echo "FAIL: Expected 1 worktree, found $WORKTREE_COUNT"
   ```

4. Verify only one tmux window for t001
   ```bash
   WINDOW_COUNT=$(tmux list-windows -t "ace-e2e-test" 2>&1 | grep -c "t001")
   [ "$WINDOW_COUNT" -eq 1 ] && echo "PASS: Exactly 1 tmux window t001" || echo "FAIL: Expected 1 window, found $WINDOW_COUNT"
   ```

## Expected

- Exit code: 0
- Exactly 1 worktree for task 001 (reused, not duplicated)
- Exactly 1 tmux window "t001" (reused, not duplicated)
