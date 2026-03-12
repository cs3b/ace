---
name: as-task-work
description: Execute task implementation with context loading and change commits
# bundle: wfi://task/work
context: fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
  - Task
argument-hint: [task-id like 123]
last_modified: 2026-02-17
source: ace-task
integration:
  providers:
    codex:
      frontmatter:
        model: gpt-5.3-codex-spark
assign:
  source: wfi://task/work
skill:
  kind: workflow
  execution:
    workflow: wfi://task/work
---

## Instructions

- read and run `ace-bundle wfi://task/work`
