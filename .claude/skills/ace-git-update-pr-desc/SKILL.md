---
name: ace-git-update-pr-desc
description: Update PR description based on current work
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
  - Grep
argument-hint: "[#]"
last_modified: 2026-01-10
source: ace-git
---

read and run `ace-bundle wfi://git/update-pr-desc`
