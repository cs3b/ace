---
name: as-handbook-selfimprove
description: Analyze mistakes to improve processes, then fix the immediate issue
# bundle: wfi://retro/selfimprove
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [description of what went wrong]
last_modified: 2026-03-10
source: ace-retro
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
    workflow: wfi://retro/selfimprove
---

read and run `ace-bundle wfi://retro/selfimprove`
