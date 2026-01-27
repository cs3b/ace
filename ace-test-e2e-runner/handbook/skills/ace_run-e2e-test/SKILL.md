---
name: ace:run-e2e-test
description: Execute an E2E test scenario
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(ruby:*)
  - Read
  - Write
  - Glob
  - Grep
argument-hint: "[package] [test-id]"
last_modified: 2026-01-19
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://run-e2e-test`

ARGUMENTS: $ARGUMENTS
