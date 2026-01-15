---
name: ace:create-test-cases
description: Generate structured test cases for features and code changes
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Read
  - Write
  - Edit
argument-hint:
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://create-test-cases`
