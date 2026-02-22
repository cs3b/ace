---
name: ace-e2e-run-batch
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
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/run-batch`

ARGUMENTS: $ARGUMENTS
