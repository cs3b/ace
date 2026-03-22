---
name: as-git-worktree-create
description: Create task-aware or branch-based git worktrees with guided automation
# bundle: wfi://git/worktree-create
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-worktree:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [--task TASK_ID|--branch BRANCH]
last_modified: 2026-03-12
source: ace-git-worktree
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree-create
---

Load and run `ace-bundle wfi://git/worktree-create` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
