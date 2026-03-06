---
name: as-e2e-review
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
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/review`

ARGUMENTS: $ARGUMENTS
