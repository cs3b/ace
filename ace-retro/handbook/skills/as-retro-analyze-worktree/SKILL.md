---
name: as-retro-analyze-worktree
description: Analyze completed worktrees or a whole fleet for scope-vs-outcome drift, post-completion activity, and `.ace-local` quality telemetry
# bundle: wfi://retro/analyze-worktree
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-retro:*)
  - Bash(ace-task:*)
  - Bash(ace-assign:*)
  - Bash(git:*)
  - Bash(rg:*)
  - Read
  - Write
  - Edit
  - MultiEdit
  - TodoWrite
last_modified: 2026-04-11
source: ace-retro
skill:
  kind: workflow
  execution:
    workflow: wfi://retro/analyze-worktree
---

Load and run `ace-bundle wfi://retro/analyze-worktree` in the current project, then follow it end-to-end using fleet mode when a parent worktree container is available.
