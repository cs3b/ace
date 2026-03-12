---
name: as-handbook-parallel-research
description: Set up and run parallel agent research
# bundle: wfi://handbook/parallel-research
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Glob
argument-hint: "[topic] --agents claude,gemini,codex"
last_modified: 2026-01-31
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
    workflow: wfi://handbook/parallel-research
---

read and run `ace-bundle wfi://handbook/parallel-research`
