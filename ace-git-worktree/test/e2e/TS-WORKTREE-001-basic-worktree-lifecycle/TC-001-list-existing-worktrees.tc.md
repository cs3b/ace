---
tc-id: TC-001
title: List Existing Worktrees
---

## Objective

Verify that `ace-git-worktree list` shows the main worktree in a fresh repository.

## Steps

1. List worktrees in a fresh repository
   ```bash
   ace-git-worktree list
   ```

## Expected

- Exit code: 0
- Output shows the main worktree (current directory)
- Shows branch name (main)
