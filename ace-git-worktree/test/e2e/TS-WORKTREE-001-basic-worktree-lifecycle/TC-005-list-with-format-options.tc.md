---
tc-id: TC-005
title: List with Format Options
---

## Objective

Verify list command format options work correctly.

## Steps

1. List worktrees in table format (default)
   ```bash
   ace-git-worktree list --format table
   ```

2. List worktrees in JSON format
   ```bash
   ace-git-worktree list --format json
   ```

3. List worktrees in simple format
   ```bash
   ace-git-worktree list --format simple
   ```

## Expected

- Table format: Shows columns with branch, path, status
- JSON format: Valid JSON array with worktree objects
- Simple format: One path per line
