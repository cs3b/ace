---
name: ace_task_document-unplanned
description: Document Unplanned Work
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [description]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://task/document-unplanned`

read and run `ace-bundle wfi://git/commit`
