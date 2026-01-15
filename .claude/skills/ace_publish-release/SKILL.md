---
name: ace:publish-release
description: Finalize and publish release with tag creation and announcements
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
argument-hint: [release-version]
last_modified: 2026-01-10
source: ace-taskflow
---

read and run `ace-context wfi://publish-release`

read and run `ace-context wfi://commit`
