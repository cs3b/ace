---
name: as-github-pr-create
description: Create GitHub pull request with generated description and summary
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Bash(gh:*)
- Read
argument-hint: pr-type
last_modified: 2026-01-10
source: ace-git
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/create
---

read and run `ace-bundle wfi://github/pr/create`
