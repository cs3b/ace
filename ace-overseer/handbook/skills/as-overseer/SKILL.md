---
name: as-overseer
description: Orchestrate task worktrees with ace-overseer (work-on, status, prune)
# bundle: wfi://overseer
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-overseer:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[task-ref] [--preset name]"
last_modified: 2026-02-17
source: ace-overseer
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
    workflow: wfi://overseer
---

read and run `ace-bundle wfi://overseer`
