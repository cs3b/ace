---
name: ace:coworker-drive-session
description: Drive agent execution through an active coworker session
# bundle: wfi://drive-coworker-session
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-coworker:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
  - Skill
argument-hint: ""
last_modified: 2026-01-28
source: ace-coworker
---

read and run `ace-bundle wfi://drive-coworker-session`
