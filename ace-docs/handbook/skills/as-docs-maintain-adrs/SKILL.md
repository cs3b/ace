---
name: as-docs-maintain-adrs
description: Maintain ADR lifecycle (evolve, archive, sync)
# bundle: wfi://docs/maintain-adrs
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
source: ace-docs
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/maintain-adrs
---

Load and run `mise exec -- ace-bundle wfi://docs/maintain-adrs` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

