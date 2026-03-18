---
name: as-assign-compose
description: Compose a tailored assignment from ace-assign catalog steps and composition rules (catalog-only)
# bundle: wfi://assign/compose
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Glob
  - Read
  - Write
  - AskUserQuestion
argument-hint: '"description of what you need" [--taskref value] [--taskrefs values]'
last_modified: 2026-02-13
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/compose

---

Load and run `mise exec -- ace-bundle wfi://assign/compose` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
