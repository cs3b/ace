---
name: ace:capture-features
description: Capture Application Features
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
argument-hint: [app-path]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-bundle wfi://capture-application-features`

read and run `ace-bundle wfi://git/commit`
