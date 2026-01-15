---
name: ace:draft-tasks
description: Draft multiple tasks from idea files with structured specifications
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Read
  - Task
argument-hint: [idea-pattern]
source: ace-taskflow
---

read and run `ace-context wfi://draft-tasks`
