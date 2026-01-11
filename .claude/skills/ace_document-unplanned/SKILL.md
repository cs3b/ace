---
name: ace:document-unplanned
description: Document Unplanned Work
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [description]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://document-unplanned-work`

read and run `ace-context wfi://commit`
