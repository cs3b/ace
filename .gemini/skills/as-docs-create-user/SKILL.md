---
name: as-docs-create-user
description: Create User Docs
user-invocable: true
allowed-tools:
- Bash(ace-docs:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- feature-description
last_modified: 2026-01-10
source: ace-docs
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/create-user
---

read and run `ace-bundle wfi://docs/create-user`
