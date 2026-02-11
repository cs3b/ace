---
tc-id: TC-007
title: Remove with Dry Run
---

## Objective

Verify --dry-run shows what would be removed without removing.

## Steps

1. Dry-run removal of the new-feature worktree
   ```bash
   ace-git-worktree remove new-feature --dry-run
   ```

2. Verify worktree still exists
   ```bash
   WORKTREES_ROOT="$(pwd)/../worktrees"
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory still exists - PASS"
   ace-git-worktree list | grep new-feature && echo "Still in list - PASS"
   ```

## Expected

- Exit code: 0
- Output indicates what would be removed
- Worktree directory still exists
- Still appears in worktree list
