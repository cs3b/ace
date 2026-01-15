---
name: initialize-project-structure
description: Initialize Project Structure
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
argument-hint: [project-path]
last_modified: 2026-01-10
source: generated
---

read and run `ace-context wfi://initialize-project-structure`

read and run `ace-context wfi://commit`
