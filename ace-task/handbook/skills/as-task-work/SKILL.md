---
name: as-task-work
description: Execute task implementation with context loading and change commits
# bundle: wfi://task/work
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
assign:
  source: wfi://task/work
  steps:
    - name: work-on-task
      description: Implement task changes following project conventions
      intent:
        phrases:
          - "work on task"
          - "implement task"
          - "task work"
          - "build feature"
      tags: [implementation, core-workflow]
      context:
        default: fork
skill:
  kind: workflow
  execution:
    workflow: wfi://task/work
---

## Instructions

- read and run `ace-bundle wfi://task/work`
