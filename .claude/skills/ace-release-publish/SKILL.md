---
name: ace-release-publish
description: Finalize and publish release with tag creation and announcements
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
argument-hint: [release-version]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://release/publish`

read and run `ace-bundle wfi://git/commit`
