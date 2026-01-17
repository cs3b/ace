---
name: ace:work-on-subtasks
description: Work On Subtasks (orchestrator task delegation)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
  - AskUserQuestion
  - TodoWrite
argument-hint: [orchestrator-task-id]
source: ace-taskflow
---

read and run `ace-bundle wfi://work-on-subtasks`

ARGUMENTS: $ARGUMENTS
