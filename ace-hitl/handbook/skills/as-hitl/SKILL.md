---
name: as-hitl
description: Manage human-attention blockers and completion handoffs with ace-hitl
# bundle: wfi://hitl
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-hitl:*)
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[create|list|show|update] [options]"
last_modified: 2026-04-02
source: ace-hitl
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
    workflow: wfi://hitl
---

Load and run `ace-bundle wfi://hitl` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
