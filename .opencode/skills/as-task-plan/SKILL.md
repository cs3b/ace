---
name: as-task-plan
description: Creates JIT implementation plan with ephemeral output, no task file modifications
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
- TodoWrite
argument-hint:
- task-id
last_modified: 2026-03-09
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/plan
assign:
  source: wfi://task/plan
---

Load and run `mise exec -- ace-bundle wfi://task/plan` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
