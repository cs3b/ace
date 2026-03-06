---
name: as-lint-fix-issue-from
description: Fix linting issues identified in ace-lint report output
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
argument-hint: [linter-output-file]
last_modified: 2026-01-10
source: generated
---

read and run `ace-bundle wfi://lint/run`

read and run `ace-bundle wfi://git/commit`
