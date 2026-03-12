---
name: as-task-document-unplanned
description: Document Unplanned Work
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- TodoWrite
argument-hint:
- description
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/document-unplanned
---

read and run `ace-bundle wfi://task/document-unplanned`
