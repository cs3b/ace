---
name: as-git-reorganize-commits
description: Reorganize commits into logical groups
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [version]
last_modified: 2026-01-19
source: ace-git
---

read and run `ace-bundle wfi://git/reorganize-commits`
