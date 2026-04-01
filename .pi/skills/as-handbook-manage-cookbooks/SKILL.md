---
name: as-handbook-manage-cookbooks
description: Create, update, and maintain cookbook assets and standards
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
argument-hint: "[cookbook-name] [action: create|update|review]"
last_modified: 2026-04-01
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/manage-cookbooks
---

Load and run `ace-bundle wfi://handbook/manage-cookbooks` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
