---
name: ace:review-task
description: Review task specification for completeness and implementation readiness
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-id like 123]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://review-task`

read and run `ace-context wfi://commit`
