---
name: as-task-review
description: Reviews draft behavioral specs, promotes to pending when ready
# bundle: wfi://task/review
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-id like 123]
last_modified: 2026-02-16
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/review

---

Load and run `ace-bundle wfi://task/review` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

