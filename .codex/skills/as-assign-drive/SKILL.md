---
name: as-assign-drive
description: Drive agent execution through an active assignment
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
- Treat `ace-assign status --assignment <id>@<root>` as the source of truth for fork completion; quiet terminal output is not enough reason to stop or declare a stall.
- If a prior terminal or drive session ended, re-enter from assignment state and continue from the next runnable work instead of depending on the old terminal handle.
- Use progress updates for partial status only.
- Return a final user-facing completion response only when the assignment is complete or the workflow reaches an explicit blocker/failure stop condition.
- If pending work remains runnable, continue driving.
