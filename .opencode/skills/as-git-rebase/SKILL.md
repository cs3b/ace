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

Load and run `mise exec -- ace-bundle wfi://git/rebase` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
