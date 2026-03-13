---
name: as-handbook-selfimprove
description: Analyze mistakes to improve processes, then fix the immediate issue
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- description of what went wrong
last_modified: 2026-03-10
source: ace-retro
skill:
  kind: workflow
  execution:
    workflow: wfi://retro/selfimprove
---

Load and run `mise exec -- ace-bundle wfi://retro/selfimprove` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
