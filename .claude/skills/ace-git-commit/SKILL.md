---
name: ace-git-commit
description: Generate intelligent git commit message from staged or all changes
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-commit:*) 
  - Bash(ace-git:*) 
  - Bash(ace-bundle:*) 
  - Read
argument-hint: [intention]
last_modified: 2026-01-10
source: ace-git-commit
---

read and run `ace-bundle wfi://git/commit`
