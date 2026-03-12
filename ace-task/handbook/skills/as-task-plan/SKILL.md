---
name: as-task-plan
description: Creates JIT implementation plan with ephemeral output, no task file modifications
# bundle: wfi://task/plan
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: [task-id]
last_modified: 2026-03-09
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/plan
assign:
  source: wfi://task/plan
---

read and run `ace-bundle wfi://task/plan`
