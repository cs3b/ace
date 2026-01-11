---
name: ace:maintain-adrs
description: Maintain ADR lifecycle (evolve, archive, sync)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-docs:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [action: review|archive|evolve|sync]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://maintain-adrs`

read and run `ace-context wfi://commit`
