---
name: as-reflect-and-refactor-internal
description: Internal helper for architecture reflection and bounded refactoring
user-invocable: false
allowed-tools:
- Bash(ace-review:*)
- Bash(ace-git-commit:*)
- Read
- Write
argument-hint: "[assignment-context]"
last_modified: 2026-04-05
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/reflect-and-refactor-internal
assign:
  source: wfi://assign/reflect-and-refactor-internal
  steps:
  - name: reflect-and-refactor
    description: Run architecture reflection and execute bounded refactoring
    prerequisites:
    - name: work-on-task
      strength: required
---

Load and run `ace-bundle wfi://assign/reflect-and-refactor-internal` in the current project, then follow the loaded workflow as the source of truth.
