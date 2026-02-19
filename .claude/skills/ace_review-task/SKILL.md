---
name: ace:review-task
description: Reviews draft behavioral specs, promotes to pending when ready
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-id like 123]
last_modified: 2026-02-16
source: ace-taskflow
---

read and run `ace-bundle wfi://review-task`

read and run `ace-bundle wfi://git/commit`
