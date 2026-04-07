# bundle: wfi://assign/create-retro-internal
# agent: general-purpose
---
name: as-create-retro-internal
description: Internal helper for retrospective creation in assignment closeout
user-invocable: false
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-retro:*)
  - Read
  - Write
argument-hint: "[retro-title]"
last_modified: 2026-04-05
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/create-retro-internal
assign:
  source: wfi://assign/create-retro-internal
  steps:
    - name: create-retro
      description: Create retrospective summarizing outcomes and lessons
      prerequisites:
        - name: reflect-and-refactor
          strength: recommended
---

Load and run `ace-bundle wfi://assign/create-retro-internal` in the current project, then follow the loaded workflow as the source of truth.
