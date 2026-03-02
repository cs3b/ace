---
name: ace-task-draft-batch
description: Draft multiple tasks from idea files with structured specifications
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Task
argument-hint: [idea-pattern]
source: ace-task
---

read and run `ace-bundle wfi://task/draft-batch`
