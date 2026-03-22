---
name: as-task-update
description: Update task metadata, status, position, or location
# bundle: wfi://task/update
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "<ref> [--set K=V] [--move-to FOLDER] [--move-as-child-of PARENT|none] [--position first|after:<ref>]"
last_modified: 2026-03-21
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/update

---

Load and run `ace-bundle wfi://task/update` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
