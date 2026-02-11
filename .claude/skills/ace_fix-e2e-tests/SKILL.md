---
name: ace:fix-e2e-tests
description: Diagnose and fix failing E2E tests systematically
# bundle:
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-test-suite:*)
  - Bash(git:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: "[package] [test-id]"
last_modified: 2026-02-11
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://fix-e2e-tests`

ARGUMENTS: $ARGUMENTS
