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

Load and run `mise exec -- ace-bundle wfi://git/reorganize-commits` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
