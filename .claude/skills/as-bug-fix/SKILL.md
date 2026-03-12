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

read and run `ace-bundle wfi://bug/fix`
