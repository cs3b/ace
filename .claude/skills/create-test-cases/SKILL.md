---
name: create-test-cases
description: Create Test Cases
# context: no-fork
# agent: Plan
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
argument-hint: [feature-description]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://create-test-cases`

read and run `ace-context wfi://commit`
