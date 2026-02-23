---
name: ace-task-draft
description: Draft Task with Idea File Movement (SPECS ONLY - no code)
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [task-description or idea-file-path]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://task/draft`
