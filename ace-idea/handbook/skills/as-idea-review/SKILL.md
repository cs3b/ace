---
name: as-idea-review
description: Critically review ideas for clarity, feasibility, and readiness for task creation
# bundle: wfi://idea/review
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-idea:*)
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
  - MultiEdit
  - TodoWrite
argument-hint: [idea-id]
last_modified: 2026-03-12
source: ace-idea
skill:
  kind: workflow
  execution:
    workflow: wfi://idea/review
---

Load and run `mise exec -- ace-bundle wfi://idea/review` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
