---
name: ace-task-improve-coverage
description: Analyze coverage and create targeted test tasks to improve coverage
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: "[package-path] [target-percent]"
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://task/improve-coverage`
