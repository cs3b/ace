---
name: ace:plan-e2e-changes
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
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://plan-e2e-changes`

ARGUMENTS: $ARGUMENTS
