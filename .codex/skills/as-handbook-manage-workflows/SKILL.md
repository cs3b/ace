---
name: as-handbook-manage-workflows
description: Create, update, and maintain workflow instruction files
user-invocable: true
allowed-tools:
- Bash(ace-handbook:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- MultiEdit
- Glob
- LS
- TodoWrite
argument-hint: "[workflow-name] [action: create|update|review]"
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/manage-workflows
---

Load and run `mise exec -- ace-bundle wfi://handbook/manage-workflows` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
