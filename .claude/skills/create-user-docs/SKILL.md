---
name: create-user-docs
description: Create User Docs
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-docs:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [feature-description]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://create-user-docs`

read and run `ace-context wfi://commit`
