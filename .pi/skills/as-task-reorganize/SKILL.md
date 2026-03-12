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

read and run `ace-bundle wfi://task/reorganize`
