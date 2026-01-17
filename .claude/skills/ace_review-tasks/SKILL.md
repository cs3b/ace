---
name: ace:review-tasks
description: Review Multiple Tasks
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
argument-hint: [task-id-pattern like 12* or *]
source: ace-taskflow
---

read and run `ace-bundle wfi://review-tasks`

ARGUMENTS: $ARGUMENTS
