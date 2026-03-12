---
name: as-bundle
description: Load project context from preset names, file paths, or protocol URLs
# bundle: wfi://bundle
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
argument-hint: ["preset|file-path|protocol"]
last_modified: 2026-01-10
source: ace-bundle
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
    workflow: wfi://bundle
---

read and run `ace-bundle wfi://bundle`
