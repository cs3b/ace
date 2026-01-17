---
name: ace:plan-tasks
description: Plan Multiple Draft Tasks
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
argument-hint: [task-id-pattern like 12* or *]
source: ace-taskflow
---

read and run `ace-bundle wfi://plan-tasks`

ARGUMENTS: $ARGUMENTS
