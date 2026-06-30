---
name: as-test-create-cases
description: Generate structured test cases for features and code changes
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
argument-hint:
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://test/create-cases
---

Load and run `ace-bundle wfi://test/create-cases` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
