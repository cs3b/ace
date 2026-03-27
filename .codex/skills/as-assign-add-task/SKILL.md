---
name: as-assign-add-task
description: Add a work-on-task subtree into a running assignment batch parent
# bundle: wfi://assign/add-task
# agent: general-purpose
user-invocable: true
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-bundle:*)
- Bash(ace-task:*)
- Read
- Write
- AskUserQuestion
argument-hint: "taskref [--parent STEP] [--assignment ID]"
last_modified: 2026-03-26
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/add-task

---

Load and run `ace-bundle wfi://assign/add-task` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
