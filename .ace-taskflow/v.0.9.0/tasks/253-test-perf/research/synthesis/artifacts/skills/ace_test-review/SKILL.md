---
name: ace:test-review
description: Review tests for layer fit, mock quality, and performance
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
argument-hint: [paths]
last_modified: 2026-01-31
source: planning-draft
---

read and run `ace-bundle wfi://test-review`
