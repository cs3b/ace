---
name: as-docs-update
description: Update documentation with ace-docs workflow
# bundle: wfi://docs/update
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-docs:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
argument-hint: [files or --options]
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
    workflow: wfi://docs/update
---

read and run `ace-bundle wfi://docs/update`
