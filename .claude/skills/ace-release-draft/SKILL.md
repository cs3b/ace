---
name: ace-release-draft
description: Draft new release with version bump and CHANGELOG preparation
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - TodoWrite
argument-hint: "[release-version] [codename]"
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://release/draft`

read and run `ace-bundle wfi://git/commit`
