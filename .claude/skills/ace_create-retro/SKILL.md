---
name: ace:create-retro
description: Create task retrospective documenting learnings and improvements
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [retro-title]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://create-retro`

read and run `ace-context wfi://commit`
