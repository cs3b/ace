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

2. Verify we can use the path to navigate
   ```bash
   WORKTREES_ROOT="$(pwd)/../worktrees"
   cd "$WORKTREES_ROOT/feature-wt"
   git branch --show-current
   ```

## Expected

- Exit code: 0
- Returns full path to the worktree
- Path is the feature worktree location
- Can navigate to returned path
