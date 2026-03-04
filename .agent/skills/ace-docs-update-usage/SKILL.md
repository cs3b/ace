---
name: ace-docs-update-usage
description: Update usage documentation based on feedback or requirements
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [usage-file-path or feedback-description]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://docs/update-usage`
