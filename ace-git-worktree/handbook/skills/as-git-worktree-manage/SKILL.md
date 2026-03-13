---
name: as-git-worktree-manage
description: Manage existing git worktrees for listing, switching, cleanup, and removal
# bundle: wfi://git/worktree-manage
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-worktree:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [list|switch|remove|prune|config]
last_modified: 2026-03-12
source: ace-git-worktree
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree-manage
---

read and run `ace-bundle wfi://git/worktree-manage`
