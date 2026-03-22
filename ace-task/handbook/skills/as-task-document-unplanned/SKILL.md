---
name: as-task-document-unplanned
description: Document Unplanned Work
# bundle: wfi://task/document-unplanned
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [description]
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/document-unplanned

---

Load and run `ace-bundle wfi://task/document-unplanned` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

