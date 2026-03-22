---
name: as-assign-create
description: Public assignment creation workflow (create, optionally handoff to drive with --run)
# bundle: wfi://assign/create
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[instructions|preset [params] [--run]]"
last_modified: 2026-02-11
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/create

---

Load and run `ace-bundle wfi://assign/create` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
