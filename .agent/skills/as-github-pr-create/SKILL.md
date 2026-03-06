---
# bundle: wfi://github/pr/create
# agent: general-purpose
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
---

read and run `ace-bundle wfi://github/pr/create`
