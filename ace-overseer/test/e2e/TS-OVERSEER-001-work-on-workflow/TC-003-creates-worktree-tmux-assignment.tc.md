---
tc-id: TC-003
title: Happy Path — Creates Worktree, Tmux Window, and Assignment
---

## Objective

Verify the full `ace-overseer work-on --task 001` pipeline: creates a git worktree, opens a tmux window, and initialises an assignment using the default preset.

## Steps

1. Kill any stale e2e tmux session
   ```bash
   tmux kill-session -t "ace-e2e-test" 2>/dev/null || true
   ```

2. Run work-on for task 001
   ```bash
   OUTPUT=$(ace-overseer work-on --task 001 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

4. Verify worktree was created for task 001
   ```bash
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "$WORKTREE_LIST"
   echo "$WORKTREE_LIST" | grep -q "001" && echo "PASS: Worktree for task 001 exists" || echo "FAIL: No worktree for task 001"
   ```

5. Verify tmux window was created
   ```bash
   WINDOWS=$(tmux list-windows -t "ace-e2e-test" 2>&1)
   echo "$WINDOWS"
   echo "$WINDOWS" | grep -q "t001" && echo "PASS: Tmux window t001 exists" || echo "FAIL: No tmux window t001"
   ```

6. Verify assignment was initialised
   ```bash
   WORKTREE_PATH=$(git worktree list | grep "001" | awk '{print $1}')
   if [ -n "$WORKTREE_PATH" ]; then
     ASSIGN_OUTPUT=$(cd "$WORKTREE_PATH" && PROJECT_ROOT_PATH="$WORKTREE_PATH" ace-assign status 2>&1)
     echo "$ASSIGN_OUTPUT"
     echo "$ASSIGN_OUTPUT" | grep -qiE "active|implement|work-on-task" && echo "PASS: Assignment active" || echo "FAIL: No active assignment"
   else
     echo "FAIL: Cannot check assignment — no worktree path"
   fi
   ```

## Expected

- Exit code: 0
- Git worktree created for task 001
- Tmux window "t001" created in session "ace-e2e-test"
- Assignment initialised with the default "work-on-task" preset
