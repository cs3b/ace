---
name: ace:draft-release
description: Draft new release with version bump and CHANGELOG preparation
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-context:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [release-version] [codename]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://draft-release`

read and run `ace-context wfi://commit`
