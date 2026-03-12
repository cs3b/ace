---
name: as-task-finder
description: FIND tasks - list, filter, and discover tasks
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/finder
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://task/finder`
