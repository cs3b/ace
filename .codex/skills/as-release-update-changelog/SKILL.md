---
name: as-release-update-changelog
description: Update CHANGELOG.md with recent changes following Keep a Changelog format
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
- Edit
argument-hint:
- change-description
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://release/update-changelog
---

Load and run `ace-bundle wfi://release/update-changelog` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
