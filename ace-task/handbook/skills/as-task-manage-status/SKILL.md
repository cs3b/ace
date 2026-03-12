---
name: as-task-manage-status
description: Manage task lifecycle status (start, done, undone)
# bundle: wfi://task/manage-status
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[action] [task-ref]"
last_modified: 2026-02-14
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/manage-status

---

read and run `ace-bundle wfi://task/manage-status`
