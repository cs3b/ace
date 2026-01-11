---
name: create-api-docs
description: Create API Docs
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
argument-hint: [source-path]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://create-api-docs`

read and run `ace-context wfi://commit`
