---
name: ace-task-plan
description: Creates JIT implementation plan with ephemeral output, no task file modifications
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: [task-id]
last_modified: 2026-02-16
source: ace-task
---

read and run `ace-bundle wfi://task/plan`
