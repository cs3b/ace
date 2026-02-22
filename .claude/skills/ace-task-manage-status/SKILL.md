---
name: ace-task-manage-status
description: Manage task lifecycle status (start, done, undone)
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[action] [task-ref]"
last_modified: 2026-02-14
source: ace-taskflow
---

read and run `ace-bundle load wfi://task/manage-status`
