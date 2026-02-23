---
name: ace-docs-squash-changelog
description: Squash multiple CHANGELOG.md entries into one before merge
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
  - Edit
  - Grep
argument-hint: "[target-branch]"
---

read and run `ace-bundle wfi://docs/squash-changelog`
