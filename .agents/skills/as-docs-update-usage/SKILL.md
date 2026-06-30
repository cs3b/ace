---
name: as-docs-update-usage
description: Update usage documentation based on feedback or requirements
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- usage-file-path or feedback-description
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/update-usage
---

Load and run `ace-bundle wfi://docs/update-usage` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
