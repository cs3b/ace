---
name: as-test-fix
description: Fix failing automated tests systematically
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
argument-hint:
- test-file-pattern
last_modified: 2026-02-24
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://test/fix
---

Load and run `mise exec -- ace-bundle wfi://test/fix` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
