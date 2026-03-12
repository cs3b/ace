---
name: as-task-draft
description: Draft Task with Idea File Movement (SPECS ONLY - no code)
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Read
- Write
- TodoWrite
argument-hint:
- task-description or idea-file-path
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://task/draft
---

read and run `ace-bundle wfi://task/draft`
