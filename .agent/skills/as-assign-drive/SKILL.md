---
name: as-assign-drive
description: Drive agent execution through an active assignment
# bundle: wfi://assign/drive
# agent: general-purpose
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
---

read and run `ace-bundle wfi://assign/drive`
