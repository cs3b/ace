---
name: as-test-performance-audit
description: Profile tests and document slow cases with actionable fixes
# bundle: wfi://test/performance-audit
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
argument-hint: [package | path]
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
    workflow: wfi://test/performance-audit
---

Load and run `mise exec -- ace-bundle wfi://test/performance-audit` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
