---
name: as-test-improve-coverage
description: Analyze coverage and create targeted test tasks to improve coverage
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Bash(ace-test:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint: "[package-path] [target-percent]"
last_modified: 2026-03-21
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/improve-coverage
---

Load and run `ace-bundle wfi://test/improve-coverage` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
