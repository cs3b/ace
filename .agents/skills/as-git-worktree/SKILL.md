---
name: as-git-worktree
description: Manage git worktrees with task-aware automation
user-invocable: true
allowed-tools:
- Bash(ace-git-worktree:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[create|list|switch|remove|prune|config] [options]"
last_modified: 2026-01-09
source: ace-git-worktree
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree
---

Load and run `ace-bundle wfi://git/worktree` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
