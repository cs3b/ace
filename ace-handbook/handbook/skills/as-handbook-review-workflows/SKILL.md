---
name: as-handbook-review-workflows
description: Review and validate workflow instructions for quality and consistency
# bundle: wfi://handbook/review-workflows
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
argument-hint: [workflow-name]
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
    workflow: wfi://handbook/review-workflows
---

Load and run `ace-bundle wfi://handbook/review-workflows` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
