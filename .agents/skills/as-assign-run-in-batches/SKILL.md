---
name: as-assign-run-in-batches
description: Create a generic repeated-item fan-out assignment from template + explicit
  items
user-invocable: true
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-bundle:*)
- Read
- Write
- AskUserQuestion
argument-hint: '"instruction template" --items item1,item2 [--sequential] [--max-parallel
  N] [--run]'
last_modified: 2026-03-08
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/run-in-batches
---

Load and run `ace-bundle wfi://assign/run-in-batches` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
