---
name: ace:release-navigator
description: Navigate and display release information
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[list|show] [options]"
last_modified: 2026-01-09
source: ace-taskflow
---

Execute `ace-taskflow release "$@"` to navigate releases
