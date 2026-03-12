---
name: as-docs-update-blueprint
description: Update project blueprint documentation with accurate structure, stack,
  and key files
user-invocable: true
allowed-tools:
- Bash(ace-docs:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- MultiEdit
- Glob
- Grep
- LS
- TodoWrite
argument-hint:
- project-root
last_modified: 2026-03-12
source: ace-docs
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/update-blueprint
---

read and run `ace-bundle wfi://docs/update-blueprint`
