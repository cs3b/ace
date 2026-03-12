---
name: as-handbook-manage-guides
description: Create, update, and maintain development guides
# bundle: wfi://handbook/manage-guides
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - MultiEdit
  - Glob
  - LS
  - TodoWrite
argument-hint: "[guide-name] [action: create|update|review]"
last_modified: 2026-01-10
source: ace-handbook
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
    workflow: wfi://handbook/manage-guides
---

read and run `ace-bundle wfi://handbook/manage-guides`
