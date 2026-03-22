---
name: as-review-verify-feedback
description: Verify feedback items through multi-dimensional claim analysis
# bundle: wfi://review/verify-feedback
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - Grep
  - Glob
argument-hint: "[--session <path>]"
last_modified: 2026-02-04
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
    workflow: wfi://review/verify-feedback
---

Load and run `ace-bundle wfi://review/verify-feedback` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
