---
name: as-docs-maintain-adrs
description: Maintain ADR lifecycle (evolve, archive, sync)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-docs:*)
  - Bash(ace-bundle:*)
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

read and run `ace-bundle wfi://docs/maintain-adrs`

read and run `ace-bundle wfi://git/commit`
