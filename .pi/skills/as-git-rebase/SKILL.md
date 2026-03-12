---
name: as-git-rebase
description: Rebase with CHANGELOG preservation
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
- Edit
- Write
argument-hint:
- target-branch
last_modified: 2026-01-10
source: ace-git
skill:
  kind: workflow
  execution:
    workflow: wfi://git/rebase
---

read and run `ace-bundle wfi://git/rebase`
