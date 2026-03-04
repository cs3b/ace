---
name: ace-release-bump-version
description: Increment gem version following semver with CHANGELOG updates
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
argument-hint: "[package-name] [patch|minor|major]"
last_modified: 2026-01-10
source: ace-handbook
---

read and run `ace-bundle wfi://release/bump-version`
