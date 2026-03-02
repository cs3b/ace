---
name: ace-task-review-batch
description: Review Multiple Tasks
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
argument-hint: [task-id-pattern like 12* or *]
source: ace-task
---

read and run `ace-bundle wfi://task/review-batch`

ARGUMENTS: $ARGUMENTS
