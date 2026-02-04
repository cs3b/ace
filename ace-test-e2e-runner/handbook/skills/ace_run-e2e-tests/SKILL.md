---
name: ace:run-e2e-tests
description: Run E2E test suite via ace-e2e-test-suite CLI
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Read
  - Glob
  - Grep
  - Task
argument-hint: "[package] [--sequential] [--all]"
last_modified: 2026-02-04
source: ace-test-e2e-runner
---

Run: `ace-e2e-test-suite $ARGUMENTS`
