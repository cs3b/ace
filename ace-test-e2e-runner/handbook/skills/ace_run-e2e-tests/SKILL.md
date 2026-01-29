---
name: ace:run-e2e-tests
description: Execute multiple E2E tests in parallel using subagents
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Read
  - Glob
  - Grep
  - Task
argument-hint: "[package] [--sequential] [--all]"
last_modified: 2026-01-29
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://run-e2e-tests`

ARGUMENTS: $ARGUMENTS
