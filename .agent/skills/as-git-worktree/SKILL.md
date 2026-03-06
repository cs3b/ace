---
name: as-git-worktree
description: Manage git worktrees with task-aware automation
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-worktree:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[create|list|switch|remove|prune|config] [options]"
last_modified: 2026-01-09
source: ace-git-worktree
---

read and run `ace-bundle wfi://git/worktree`
