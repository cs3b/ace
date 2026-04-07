---
name: as-task-load-internal
description: Internal helper for loading task context into assignment execution
user-invocable: false
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
argument-hint: "[taskref]"
last_modified: 2026-04-05
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/task-load-internal
assign:
  source: wfi://assign/task-load-internal
  steps:
  - name: task-load
    description: Load task behavioral spec and dependency context into assignment
      execution
    prerequisites:
    - name: onboard-base
      strength: recommended
---

Load and run `ace-bundle wfi://assign/task-load-internal` in the current project, then follow the loaded workflow as the source of truth.
