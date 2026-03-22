---
name: as-test-plan
description: Create a test responsibility map and coverage plan before writing code
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Bash(ace-test:*)
- Bash(ace-nav:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- feature | package | task
last_modified: 2026-01-31
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/plan
---

Load and run `ace-bundle wfi://test/plan` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
