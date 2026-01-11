---
name: ace:squash-pr
description: Squash commits by version
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-context:*)
  - Read
argument-hint: [version]
last_modified: 2026-01-10
source: ace-git
---

read and run `ace-context wfi://squash-pr`
