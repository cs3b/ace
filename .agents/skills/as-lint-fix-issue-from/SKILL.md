---
name: as-lint-fix-issue-from
description: Fix linting issues identified in ace-lint report output
user-invocable: true
allowed-tools:
- Bash(ace-lint:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- Grep
argument-hint:
- linter-output-file
last_modified: 2026-01-10
source: ace-lint
skill:
  kind: workflow
  execution:
    workflow: wfi://lint/run
---

Load and run `ace-bundle wfi://lint/run` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
