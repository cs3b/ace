---
name: as-git-worktree
description: Manage git worktrees with task-aware automation
# bundle: wfi://git/worktree
# context: fork for codex
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-worktree:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[create|list|switch|remove|prune|config] [options]"
last_modified: 2026-01-09
source: ace-git-worktree
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://git/worktree
---

read and run `ace-bundle wfi://git/worktree`
