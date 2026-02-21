---
tc-id: TC-003
title: Create Worktree with New Branch
---

## Objective

Verify worktree creation with a new branch using --from.

## Steps

1. Create worktree with new branch from main
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   mkdir -p "$WORKTREES_ROOT"
   ace-git-worktree create new-feature --from main --path "$WORKTREES_ROOT/new-feature-wt"
   ```

2. Verify worktree and branch
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory exists - PASS"
   cd "$WORKTREES_ROOT/new-feature-wt"
   git branch --show-current
   ```

3. Confirm branch tracks from main
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   cd "$WORKTREES_ROOT/new-feature-wt"
   git log --oneline -1
   ```

## Expected

- Exit code: 0
- Worktree directory created
- New branch "new-feature" exists
- Branch started from main's commit
