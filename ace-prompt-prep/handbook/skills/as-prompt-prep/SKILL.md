---
name: as-prompt-prep
description: Run ace-prompt-prep and follow the printed instructions
# bundle: wfi://prompt-prep
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-prompt-prep:*)
  - Bash(ace-bundle:*)
  - Read
last_modified: 2026-01-17
source: ace-prompt-prep
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
skill:
  kind: workflow
  execution:
    workflow: wfi://prompt-prep
---

Load and run `mise exec -- ace-bundle wfi://prompt-prep` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
