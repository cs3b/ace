---
name: as-bug-fix
description: Execute bug fix plan, apply changes, create tests, and verify resolution
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
- bug-description-or-analysis-file
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://bug/fix
---

Load and run `ace-bundle wfi://bug/fix` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
