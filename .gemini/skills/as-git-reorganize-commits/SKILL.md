---
name: as-git-reorganize-commits
description: Reorganize commits into logical groups
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
argument-hint:
- version
last_modified: 2026-01-19
source: ace-git
skill:
  kind: workflow
  execution:
    workflow: wfi://git/reorganize-commits
---

read and run `ace-bundle wfi://git/reorganize-commits`
