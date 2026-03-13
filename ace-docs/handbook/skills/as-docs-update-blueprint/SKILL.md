---
name: as-docs-update-blueprint
description: Update project blueprint documentation with accurate structure, stack, and key files
# bundle: wfi://docs/update-blueprint
# context: no-fork
# agent: general-purpose
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
argument-hint: [project-root]
last_modified: 2026-03-12
source: ace-docs
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/update-blueprint
---

Load and run `mise exec -- ace-bundle wfi://docs/update-blueprint` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
