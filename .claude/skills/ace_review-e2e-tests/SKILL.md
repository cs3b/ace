---
name: ace:review-e2e-tests
description: Deep exploration producing a coverage matrix of functionality, unit tests, and E2E tests
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(git:*)
  - Read
  - Glob
  - Grep
argument-hint: "<package> [--scope <scenario-id>]"
last_modified: 2026-02-11
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://review-e2e-tests`

ARGUMENTS: $ARGUMENTS
