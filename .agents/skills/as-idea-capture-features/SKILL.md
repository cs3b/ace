---
name: as-idea-capture-features
description: Capture Application Features
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- TodoWrite
argument-hint:
- app-path
last_modified: 2026-01-10
source: ace-idea
skill:
  kind: workflow
  execution:
    workflow: wfi://idea/capture-features
---

Load and run `ace-bundle wfi://idea/capture-features` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
