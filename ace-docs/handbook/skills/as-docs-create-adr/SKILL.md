---
name: as-docs-create-adr
description: Create Architecture Decision Record
# bundle: wfi://docs/create-adr
# context: no-fork
# agent: Plan
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
argument-hint: [decision-title]
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
    workflow: wfi://docs/create-adr
---

read and run `ace-bundle wfi://docs/create-adr`

