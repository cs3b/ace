---
name: as-assign-drive
description: Drive agent execution through an active assignment
user-invocable: true
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-bundle:*)
- Read
- Write
- AskUserQuestion
- Skill
argument-hint: "[assignment[@scope]]"
last_modified: 2026-02-11
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/drive
---

Load and run `ace-bundle wfi://assign/drive` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
