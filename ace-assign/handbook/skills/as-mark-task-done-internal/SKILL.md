---
name: as-mark-task-done-internal
description: Internal helper for marking tasks done with verification
# bundle: wfi://assign/mark-task-done-internal
# agent: general-purpose
user-invocable: false
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-task:*)
  - Read
  - Write
argument-hint: "[taskref]"
last_modified: 2026-04-05
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/mark-task-done-internal
assign:
  source: wfi://assign/mark-task-done-internal
  steps:
    - name: mark-task-done
      description: Mark task complete and verify persisted status
      prerequisites:
        - name: work-on-task
          strength: required
---

Load and run `ace-bundle wfi://assign/mark-task-done-internal` in the current project, then follow the loaded workflow as the source of truth.
