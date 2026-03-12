---
name: as-review-run
description: Review code changes with preset-based analysis and LLM feedback
# bundle: wfi://review/run
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: [file-path or commit-ref]
last_modified: 2026-01-10
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
    workflow: wfi://review/run
---

read and run `ace-bundle wfi://review/run`
