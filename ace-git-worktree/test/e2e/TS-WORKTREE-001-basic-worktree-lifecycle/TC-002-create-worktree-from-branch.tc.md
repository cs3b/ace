---
tc-id: TC-002
title: Create Worktree from Branch
---

## Objective

Verify worktree creation from an existing branch.

## Steps

1. Create worktree from the feature branch
   ```bash
   WORKTREES_ROOT="$(pwd)/../worktrees"
   mkdir -p "$WORKTREES_ROOT"
   ace-git-worktree create feature/test-worktree --path "$WORKTREES_ROOT/feature-wt"
   ```

2. Verify worktree was created
   ```bash
   WORKTREES_ROOT="$(pwd)/../worktrees"
   test -d "$WORKTREES_ROOT/feature-wt" && echo "Directory exists - PASS"
   test -f "$WORKTREES_ROOT/feature-wt/feature.txt" && echo "Feature file exists - PASS"
   ```

3. List worktrees to confirm
   ```bash
   ace-git-worktree list
   ```

## Expected

- Exit code: 0
- Worktree directory created at specified path
- Feature file present in worktree
- List shows both main and feature worktrees
