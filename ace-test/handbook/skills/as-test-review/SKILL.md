---
name: as-test-review
description: Review tests for layer fit, mock quality, and performance
# bundle: wfi://test/review
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-nav:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [paths | PR-number]
last_modified: 2026-01-31
source: ace-test
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
    workflow: wfi://test/review
---

Load and run `mise exec -- ace-bundle wfi://test/review` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
