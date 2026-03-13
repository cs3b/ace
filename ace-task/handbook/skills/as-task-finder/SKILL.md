---
name: as-task-finder
description: FIND tasks - list, filter, and discover tasks
# bundle: wfi://task/finder
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-task
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
    workflow: wfi://task/finder
---

read and run `ace-bundle wfi://task/finder`
