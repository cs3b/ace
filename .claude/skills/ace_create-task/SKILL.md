---
name: ace:create-task
description: Create complete task from plan (draft + plan + commit) (SPECS ONLY - no code)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [plan-description]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://create-task`
