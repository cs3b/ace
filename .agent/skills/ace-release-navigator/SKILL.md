---
name: ace-release-navigator
description: Navigate and display release information
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-task
---

Execute `ace-release "$@"` to navigate releases
