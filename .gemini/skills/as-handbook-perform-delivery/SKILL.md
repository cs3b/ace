---
name: as-handbook-perform-delivery
description: Execute complete delivery workflow with automatic step tracking
user-invocable: true
allowed-tools:
- Bash
- Read
- Write
- Edit
- TodoWrite
- Task
- AskUserQuestion
- Skill
- EnterPlanMode
- ExitPlanMode
argument-hint: "[task-ref like 215.03] or [instructions]"
last_modified: 2026-01-18
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/perform-delivery
---

Load and run `ace-bundle wfi://handbook/perform-delivery` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
