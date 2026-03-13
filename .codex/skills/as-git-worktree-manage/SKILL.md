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
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://git/worktree-manage` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
