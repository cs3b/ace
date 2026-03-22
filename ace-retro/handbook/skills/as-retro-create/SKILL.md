---
name: as-retro-create
description: Create task retrospective documenting learnings and improvements
# bundle: wfi://retro/create
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [retro-title]
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://retro/create

---

Load and run `ace-bundle wfi://retro/create` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

