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

read and run `ace-bundle wfi://assign/drive`
