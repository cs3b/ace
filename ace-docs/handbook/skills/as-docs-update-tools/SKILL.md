---
name: as-docs-update-tools
description: Update ace-* package documentation from implementation and tests
# bundle: wfi://docs/update-tools
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
  - Grep
  - LS
  - TodoWrite
argument-hint: [component]
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
    workflow: wfi://docs/update-tools
---

Load and run `ace-bundle wfi://docs/update-tools` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
