---
name: as-docs-create-adr
description: Create Architecture Decision Record
user-invocable: true
allowed-tools:
- Bash(ace-docs:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- decision-title
last_modified: 2026-01-10
source: ace-docs
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/create-adr
---

Load and run `ace-bundle wfi://docs/create-adr` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
