---
name: as-assign-prepare
description: Legacy/internal helper to prepare job.yaml from preset or informal instructions
# bundle: wfi://assign/prepare
# agent: general-purpose
user-invocable: false
allowed-tools:
  - Bash(ace-bundle:*)
  - Glob
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[preset-name] [--taskref value] [--output path]"
last_modified: 2026-02-11
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/prepare

---

Load and run `mise exec -- ace-bundle wfi://assign/prepare` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
