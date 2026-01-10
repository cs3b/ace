---
name: ace:commit
description: Generate intelligent git commit message from staged or all changes
context: fork
agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git-commit:*) 
  - Bash(ace-git:*) 
  - Bash(ace-context:*) 
  - Read
argument-hint: [intention]
last_modified: 2025-09-26
source: ace-git-commit
---

read and run `ace-context wfi://commit`
