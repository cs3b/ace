---
tc-id: TC-005
title: Preset Override with --preset Flag
---

## Objective

Verify that `ace-overseer work-on --task 002 --preset custom-e2e-preset` uses the specified preset instead of the default "work-on-task" preset.

## Steps

1. Run work-on for task 002 with custom preset
   ```bash
   OUTPUT=$(ace-overseer work-on --task 002 --preset custom-e2e-preset 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify worktree was created for task 002
   ```bash
   WORKTREE_LIST=$(git worktree list 2>&1)
   echo "$WORKTREE_LIST"
   echo "$WORKTREE_LIST" | grep -q "002" && echo "PASS: Worktree for task 002 exists" || echo "FAIL: No worktree for task 002"
   ```

4. Verify assignment uses the custom preset
   ```bash
   WORKTREE_PATH=$(git worktree list | grep "002" | awk '{print $1}' | head -1)
   if [ -n "$WORKTREE_PATH" ]; then
     ASSIGN_OUTPUT=$(cd "$WORKTREE_PATH" && PROJECT_ROOT_PATH="$WORKTREE_PATH" ace-assign status 2>&1)
     echo "$ASSIGN_OUTPUT"
     echo "$ASSIGN_OUTPUT" | grep -qiE "custom-e2e-preset|quick-fix" && echo "PASS: Custom preset applied" || echo "FAIL: Custom preset not detected"
   else
     echo "FAIL: Cannot check assignment — no worktree path"
   fi
   ```

## Expected

- Exit code: 0
- Git worktree created for task 002
- Assignment initialised with "custom-e2e-preset" (not the default "work-on-task")
