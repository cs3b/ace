---
tc-id: TC-009
title: Remove Task Worktree with Delete Branch
---

## Objective

Verify task worktree removal also deletes branch when requested.

## Steps

1. Check branch exists before removal
   ```bash
   git branch -a | grep 999 && echo "Branch exists - SETUP OK"
   ```

2. Remove worktree with branch deletion
   ```bash
   ace-git-worktree remove --task 999 --delete-branch
   ```

3. Verify branch was also deleted
   ```bash
   git branch -a | grep -v 999 && echo "Branch deleted - PASS"
   ```

## Expected

- Exit code: 0
- Worktree removed
- Associated branch also deleted
