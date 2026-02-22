---
name: ace-git-create-pr
description: Create GitHub pull request with generated description and summary
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
argument-hint: [pr-type]
last_modified: 2026-01-10
source: ace-git
---

read and run `ace-bundle wfi://git/create-pr`
