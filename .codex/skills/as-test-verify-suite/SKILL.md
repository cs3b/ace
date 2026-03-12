---
name: as-test-verify-suite
description: Verify test suite health and enforce performance budgets
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
- package | path | mode:quick|standard|deep
last_modified: 2026-01-31
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/verify-suite
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://test/verify-suite`
