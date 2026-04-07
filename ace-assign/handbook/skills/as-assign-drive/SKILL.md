---
name: as-assign-drive
description: Drive agent execution through an active assignment
# bundle: wfi://assign/drive
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
  - Skill
argument-hint: "[assignment[@scope]]"
last_modified: 2026-04-07
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/drive

---

Load and run `ace-bundle wfi://assign/drive` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

Hard stop rule:

- Do not stop after intermediate progress.
- Do not stop while waiting on a forked subtree; keep polling and resume the parent drive loop as soon as the subtree reaches a terminal state.
- Use progress updates for partial status only.
- Return a final user-facing completion response only when the assignment is complete or the workflow reaches an explicit blocker/failure stop condition.
- If pending work remains runnable, continue driving.
