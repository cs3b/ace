---
name: ace:test-fix
description: Fix failing automated tests systematically
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [test-file-pattern]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://test/fix`
