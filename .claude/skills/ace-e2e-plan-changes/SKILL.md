---
name: ace-e2e-plan-changes
description: Analyze coverage matrix and produce a concrete E2E test change plan
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(git:*)
  - Read
  - Glob
  - Grep
  - Skill
argument-hint: "<package> [--review-report <path>] [--scope <scenario-id>]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/plan-changes`

ARGUMENTS: $ARGUMENTS
