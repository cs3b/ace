---
name: as-test-optimize
description: Profile and refactor slow tests to restore fast-loop performance
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
- package | path
last_modified: 2026-01-31
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/optimize
---

read and run `ace-bundle wfi://test/optimize`
