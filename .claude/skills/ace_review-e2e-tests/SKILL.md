---
name: ace:review-e2e-tests
description: Review E2E tests for health, coverage gaps, and outdated scenarios
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(git:*)
  - Read
  - Glob
  - Grep
argument-hint: "[package] [--all]"
last_modified: 2026-01-19
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://review-e2e-tests`

ARGUMENTS: $ARGUMENTS
