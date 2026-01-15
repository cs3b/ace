---
name: ace:work-on-task
description: Execute task implementation with context loading and change commits
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
  - Task
  - AskUserQuestion
argument-hint: [task-id like 123]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://work-on-task`

read and run `ace-context wfi://commit`
