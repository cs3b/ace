---
# bundle: wfi://github/pr/update
# agent: general-purpose
name: ace-github-pr-update
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
---

read and run `ace-bundle wfi://github/pr/update`
