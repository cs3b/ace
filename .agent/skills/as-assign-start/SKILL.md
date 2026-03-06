---
name: as-assign-start
description: Create and start an assignment from preset or instructions (compose/prepare + create)
# bundle: wfi://assign/start
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
argument-hint: "[preset-name] [--taskref value] [--taskrefs values]"
last_modified: 2026-02-11
source: ace-assign
---

read and run `ace-bundle wfi://assign/start`
