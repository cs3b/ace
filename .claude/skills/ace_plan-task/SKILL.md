---
name: ace:plan-task
description: Create implementation plan for task with research and acceptance criteria
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-id]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://plan-task`

read and run `ace-bundle wfi://commit`
