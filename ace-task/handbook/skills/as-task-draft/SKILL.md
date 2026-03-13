---
name: as-task-draft
description: Draft Task with Idea File Movement (SPECS ONLY - no code)
# bundle: wfi://task/draft
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-description or idea-file-path]
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/draft

---

Load and run `mise exec -- ace-bundle wfi://task/draft` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
