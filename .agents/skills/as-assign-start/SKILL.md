---
name: as-assign-start
description: Legacy compatibility orchestration that routes assignment startup through
  create then drive
user-invocable: false
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-bundle:*)
- Read
- Write
- AskUserQuestion
argument-hint: "[instructions|preset [params] [--run]]"
last_modified: 2026-03-09
source: ace-assign
skill:
  kind: orchestration
  execution:
    workflow: wfi://assign/start
assign:
  source: wfi://assign/start
---

Load and run `ace-bundle wfi://assign/start` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
