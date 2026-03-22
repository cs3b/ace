---
name: as-lint-process-report
description: Process lint report and create tasks for manual fixes
# bundle: wfi://lint/process-report
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [report-path]
last_modified: 2026-03-10
source: ace-lint
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
    workflow: wfi://lint/process-report
---

Load and run `ace-bundle wfi://lint/process-report` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
