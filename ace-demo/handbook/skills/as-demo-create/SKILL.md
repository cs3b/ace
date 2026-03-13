---
name: as-demo-create
description: Create or update VHS demo tapes from shell commands
# bundle: wfi://demo/create
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-demo:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "<name> [--force] -- <commands...>"
last_modified: 2026-03-05
source: ace-demo
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
    workflow: wfi://demo/create
---

Load and run `mise exec -- ace-bundle wfi://demo/create` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
