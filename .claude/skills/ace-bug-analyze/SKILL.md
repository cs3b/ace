---
name: ace-bug-analyze
description: Analyze bugs to identify root cause, reproduction status, and fix plan
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [bug-description]
last_modified: 2025-12-09
source: ace-task
---

read and run `ace-bundle wfi://bug/analyze`
