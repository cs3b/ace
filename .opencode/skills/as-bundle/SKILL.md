---
name: as-bundle
description: Load project context from preset names, file paths, or protocol URLs
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
argument-hint:
- preset|file-path|protocol
last_modified: 2026-01-10
source: ace-bundle
skill:
  kind: workflow
  execution:
    workflow: wfi://bundle
---

read and run `ace-bundle wfi://bundle`
