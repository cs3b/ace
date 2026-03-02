---
name: ace-idea-capture-features
description: Capture Application Features
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [app-path]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://idea/capture-features`

read and run `ace-bundle wfi://git/commit`
