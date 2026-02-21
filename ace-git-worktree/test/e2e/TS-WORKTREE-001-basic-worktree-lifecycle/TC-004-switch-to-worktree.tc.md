---
tc-id: TC-004
title: Switch to Worktree
---

## Objective

Verify switching to a worktree returns its path.

## Steps

1. Get worktree path for feature branch
   ```bash
   SWITCH_PATH=$(ace-git-worktree switch feature/test-worktree)
   echo "Switch path: $SWITCH_PATH"
   ```

2. Verify the returned path exists and is navigable
   ```bash
   echo "Switch returned: $SWITCH_PATH"
   [ -n "$SWITCH_PATH" ] && echo "PASS: Switch returned a path" || echo "FAIL: Switch returned empty path"
   [ -d "$SWITCH_PATH" ] && echo "PASS: Switch path is a valid directory" || echo "FAIL: Switch path does not exist"
   cd "$SWITCH_PATH"
   git branch --show-current
   ```

## Expected

- Exit code: 0
- Returns full path to the worktree
- Path is the feature worktree location
- Can navigate to returned path
