---
name: as-docs-create-user
description: Create User Docs
# bundle: wfi://docs/create-user
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
argument-hint: [feature-description]
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
    workflow: wfi://docs/create-user
---

Load and run `mise exec -- ace-bundle wfi://docs/create-user` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

