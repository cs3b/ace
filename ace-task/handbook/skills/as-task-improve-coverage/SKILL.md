---
name: as-task-improve-coverage
description: Analyze coverage and create targeted test tasks to improve coverage
# bundle: wfi://task/improve-coverage
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: "[package-path] [target-percent]"
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/improve-coverage

---

Load and run `mise exec -- ace-bundle wfi://task/improve-coverage` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
