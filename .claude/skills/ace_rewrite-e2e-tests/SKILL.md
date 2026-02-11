---
name: ace:rewrite-e2e-tests
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
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://rewrite-e2e-tests`

ARGUMENTS: $ARGUMENTS
