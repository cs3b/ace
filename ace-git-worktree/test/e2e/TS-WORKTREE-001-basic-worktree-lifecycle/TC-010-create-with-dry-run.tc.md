---
tc-id: TC-010
title: Create with Dry Run
---

## Objective

Verify create --dry-run shows what would be created without creating.

## Steps

1. Dry-run worktree creation
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   ace-git-worktree create bugfix/test-fix --path "$WORKTREES_ROOT/bugfix-wt" --dry-run
   ```

2. Verify nothing was created
   ```bash
   WORKTREES_ROOT="$(pwd)/worktrees"
   test ! -d "$WORKTREES_ROOT/bugfix-wt" && echo "Directory not created - PASS"
   ```

## Expected

- Exit code: 0
- Output shows what would be created
- No directory actually created
