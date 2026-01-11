---
name: ace:load-context
description: Load project context from preset names, file paths, or protocol URLs
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-context:*)
  - Read
argument-hint: ["preset|file-path|protocol"]
last_modified: 2026-01-10
source: ace-context
---

Run `ace-context project`, read the output (stdo or file path). And Wait for user further instructions.
