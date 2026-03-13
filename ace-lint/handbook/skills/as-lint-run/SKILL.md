---
name: as-lint-run
description: Run ace-lint on project files with optional autofix and report
# bundle: wfi://lint/run
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[file-pattern] [--fix] [--report]"
last_modified: 2026-03-10
source: ace-lint
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
    workflow: wfi://lint/run
---

read and run `ace-bundle wfi://lint/run`
