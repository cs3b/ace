---
name: ace_task_finder
description: FIND tasks - list, filter, and discover tasks
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-taskflow
---

Execute `ace-taskflow tasks "$@"` to find tasks
