---
name: ace-test-fix
description: Fix failing automated tests systematically
# context: no-fork
# agent: general-purpose
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
argument-hint: [test-file-pattern]
last_modified: 2026-02-24
source: ace-task
---

read and run `ace-bundle wfi://test/analyze-failures`
read and run `ace-bundle wfi://test/fix`
