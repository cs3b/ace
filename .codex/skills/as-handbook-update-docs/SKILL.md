---
name: as-handbook-update-docs
description: Update and maintain handbook documentation and README files
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
argument-hint:
- section
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/update-docs
---

Load and run `mise exec -- ace-bundle wfi://handbook/update-docs` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
