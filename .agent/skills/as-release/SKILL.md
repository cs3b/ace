---
# bundle: wfi://release/publish
# agent: general-purpose
name: as-release
description: Release modified ACE packages with coordinated package and root changelog updates
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-git-commit:*)
  - Bash(ace-bundle:*)
  - Bash(bundle:*)
  - Read
  - Edit
argument-hint: package-name... bump-level
last_modified: 2026-03-08
source: ace-handbook
warning: ALL steps must be completed - there are TWO separate CHANGELOG.md files
---

# Release Packages

read and run `ace-bundle wfi://release/publish`
