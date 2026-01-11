---
name: ace:update-docs
description: Update documentation with ace-docs workflow
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-docs:*)
  - Bash(ace-context:*)
  - Read
  - Write
argument-hint: [files or --options]
last_modified: 2026-01-10
source: ace-docs
---

read and run `ace-context wfi://update-docs`
