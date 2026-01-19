---
name: ace:squash-commits
description: Squash commits by version
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

read and run `ace-bundle wfi://squash-commits`
