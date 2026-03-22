---
name: as-overseer
description: Orchestrate task worktrees with ace-overseer (work-on, status, prune)
user-invocable: true
allowed-tools:
- Bash(ace-overseer:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[task-ref] [--preset name]"
last_modified: 2026-02-17
source: ace-overseer
skill:
  kind: workflow
  execution:
    workflow: wfi://overseer
---

Load and run `ace-bundle wfi://overseer` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
