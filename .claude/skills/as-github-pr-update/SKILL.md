---
name: as-github-pr-update
description: Update PR description based on current work
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Bash(gh:*)
- Read
- Grep
argument-hint: pr-number
last_modified: 2026-01-10
source: ace-git
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/update
---

Load and run `mise exec -- ace-bundle wfi://github/pr/update` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
