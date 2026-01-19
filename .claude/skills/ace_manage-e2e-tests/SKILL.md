---
name: ace:manage-e2e-tests
description: Orchestrate E2E test lifecycle (review, create, run)
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(git:*)
  - Bash(mkdir:*)
  - Read
  - Write
  - Glob
  - Grep
  - Skill
argument-hint: [package] [--since <commit/date>] [--dry-run] [--run-tests]
last_modified: 2026-01-19
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://manage-e2e-tests`

ARGUMENTS: $ARGUMENTS
