---
name: ace-test-verify-suite
description: Verify test suite health and enforce performance budgets
# context: no-fork
# agent: general-purpose
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
argument-hint: [package | path | mode:quick|standard|deep]
last_modified: 2026-01-31
source: ace-test
---

read and run `ace-bundle wfi://test/verify-suite`
