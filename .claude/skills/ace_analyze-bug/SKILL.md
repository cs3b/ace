---
name: ace:analyze-bug
description: Analyze bugs to identify root cause, reproduction status, and fix plan
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [bug-description]
last_modified: 2025-12-09
source: ace-taskflow
---

read and run `ace-context wfi://analyze-bug`
