---
name: as-git-worktree-cleanup
description: Safely inventory and apply cleanup plans for squash-merged worktrees and refs
# bundle: wfi://git/worktree-cleanup
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-worktree:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [--target main]
last_modified: 2026-08-13
source: ace-git-worktree
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree-cleanup
---

Load and run `ace-bundle wfi://git/worktree-cleanup` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
