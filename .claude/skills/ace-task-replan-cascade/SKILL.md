---
name: ace-task-replan-cascade
description: Revise task plan and propagate changes to dependent subtasks
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-id like 123]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://task/replan-cascade`

read and run `ace-bundle wfi://git/commit`
