---
name: as-integration-update-claude
description: Maintain Claude Code integration and synchronize commands
# bundle: wfi://integration/update-claude
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
argument-hint: [full|commands|agents|meta]
last_modified: 2026-01-10
source: ace-handbook-integration-claude
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
    workflow: wfi://integration/update-claude
---

read and run `ace-bundle wfi://integration/update-claude`
