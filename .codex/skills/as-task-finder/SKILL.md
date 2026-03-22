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
---

Load and run `ace-bundle wfi://task/finder` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
