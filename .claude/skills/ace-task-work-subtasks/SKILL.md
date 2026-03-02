---
name: ace-task-work-subtasks
description: Work On Subtasks (orchestrator task delegation)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
  - AskUserQuestion
  - TodoWrite
argument-hint: [orchestrator-task-id]
source: ace-task
---

read and run `ace-bundle wfi://task/work-subtasks`

ARGUMENTS: $ARGUMENTS
