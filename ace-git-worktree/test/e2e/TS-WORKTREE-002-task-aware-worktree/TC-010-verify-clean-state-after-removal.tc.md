---
tc-id: TC-010
title: Verify Clean State After Removal
---

## Objective

Verify all task worktrees removed and clean state.

## Steps

1. List all worktrees
   ```bash
   ace-git-worktree list
   ```

2. Verify no task-associated worktrees remain
   ```bash
   COUNT=$(ace-git-worktree list --task-associated --format json | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
   test "$COUNT" -eq 0 && echo "No task worktrees remain - PASS"
   ```

3. Verify main worktree still exists
   ```bash
   ace-git-worktree list | grep -E "main|master" && echo "Main worktree exists - PASS"
   ```

## Expected

- No task-associated worktrees in list
- Main worktree still present and functional
