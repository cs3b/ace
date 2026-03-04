---
name: ace-task-finder
description: FIND tasks - list, filter, and discover tasks
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-task
---

Execute `ace-task list "$@"` to find tasks
