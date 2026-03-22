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
assign:
  source: wfi://docs/update
  steps:
    - name: update-docs
      description: Update public-facing documentation when CLI contracts or public APIs change
      tags: [documentation, quality]
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/update
---

Load and run `ace-bundle wfi://docs/update` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
