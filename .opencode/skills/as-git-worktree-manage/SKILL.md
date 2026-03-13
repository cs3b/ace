---
name: as-git-worktree-manage
description: Manage existing git worktrees for listing, switching, cleanup, and removal
user-invocable: true
allowed-tools:
- Bash(ace-git-worktree:*)
- Bash(ace-bundle:*)
- Read
argument-hint:
- list|switch|remove|prune|config
last_modified: 2026-03-12
source: ace-git-worktree
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree-manage
---

Load and run `mise exec -- ace-bundle wfi://git/worktree-manage` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
