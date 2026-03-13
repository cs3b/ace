---
name: as-handbook-review-guides
description: Review and validate development guides for quality and consistency
# bundle: wfi://handbook/review-guides
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Read
  - Glob
  - LS
  - TodoWrite
argument-hint: [guide-name]
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
    workflow: wfi://handbook/review-guides
---

Load and run `mise exec -- ace-bundle wfi://handbook/review-guides` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
