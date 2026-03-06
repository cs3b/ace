---
name: as-e2e-rewrite
description: Execute a change plan — delete, create, modify, and consolidate E2E tests
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(git:*)
  - Bash(mkdir:*)
  - Bash(rm:*)
  - Read
  - Write
  - Glob
  - Grep
  - Skill
argument-hint: "<package> [--plan <path>] [--dry-run]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/rewrite`

ARGUMENTS: $ARGUMENTS
