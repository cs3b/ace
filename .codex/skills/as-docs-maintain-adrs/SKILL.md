---
name: as-docs-maintain-adrs
description: Maintain ADR lifecycle (evolve, archive, sync)
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
argument-hint:
- action: review|archive|evolve|sync
last_modified: 2026-01-10
source: ace-docs
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/maintain-adrs
---

read and run `ace-bundle wfi://docs/maintain-adrs`
