---
name: as-task-reorganize
description: Move tasks (to backlog, convert to subtask, promote to standalone, etc.)
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[operation] [task-ref] [parent-ref]"
last_modified: 2026-02-14
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/reorganize
---

Load and run `mise exec -- ace-bundle wfi://task/reorganize` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
