---
name: ace:create-e2e-test
description: Create a new E2E test scenario from template
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(mkdir:*)
  - Read
  - Write
  - Glob
  - Grep
argument-hint: <package> <area> [--context <description>]
last_modified: 2026-01-19
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://create-e2e-test`

ARGUMENTS: $ARGUMENTS
