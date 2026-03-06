---
name: as-assign-compose
description: Compose a tailored assignment from ace-assign catalog phases and composition rules (catalog-only)
# bundle: wfi://assign/compose
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: '"description of what you need" [--taskref value] [--taskrefs values]'
last_modified: 2026-02-13
source: ace-assign
---

read and run `ace-bundle wfi://assign/compose`
