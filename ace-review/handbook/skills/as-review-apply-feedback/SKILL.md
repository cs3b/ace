---
name: as-review-apply-feedback
description: Apply verified feedback items from code review
# bundle: wfi://review/apply-feedback
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: "[--session <path>] [--priority <level>]"
last_modified: 2026-02-03
source: ace-review
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
    workflow: wfi://review/apply-feedback
---

Load and run `mise exec -- ace-bundle wfi://review/apply-feedback` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
