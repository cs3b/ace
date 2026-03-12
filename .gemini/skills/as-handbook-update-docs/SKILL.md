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

read and run `ace-bundle wfi://handbook/update-docs`
