---
name: as-release-update-changelog
description: Update CHANGELOG.md with recent changes following Keep a Changelog format
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
argument-hint: [change-description]
last_modified: 2026-01-10
source: ace-handbook
---

read and run `ace-bundle wfi://release/update-changelog`
