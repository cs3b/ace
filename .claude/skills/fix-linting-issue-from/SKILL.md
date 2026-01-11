---
name: fix-linting-issue-from
description: Fix linting issues identified in ace-lint report output
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
argument-hint: [linter-output-file]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://run-lint`

read and run `ace-context wfi://commit`
