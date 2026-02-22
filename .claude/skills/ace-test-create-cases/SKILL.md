---
name: ace-test-create-cases
description: Generate structured test cases for features and code changes
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
argument-hint:
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle load wfi://test/create-cases`
