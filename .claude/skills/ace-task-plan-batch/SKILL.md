---
name: ace-task-plan-batch
description: Plan Multiple Draft Tasks
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
argument-hint: [task-id-pattern like 12* or *]
source: ace-task
---

read and run `ace-bundle wfi://task/plan-batch`

ARGUMENTS: $ARGUMENTS
