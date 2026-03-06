---
name: as-e2e-fix
description: Diagnose and fix failing E2E tests systematically
# bundle:
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-test-suite:*)
  - Bash(git:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: '[package] [test-id]'
last_modified: 2026-02-24
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/analyze-failures`
read and run `ace-bundle wfi://e2e/fix`

ARGUMENTS: $ARGUMENTS
