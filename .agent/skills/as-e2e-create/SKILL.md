---
name: as-e2e-create
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

read and run `ace-bundle wfi://e2e/create`

ARGUMENTS: $ARGUMENTS
