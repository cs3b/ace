---
name: ace:test-performance-audit
description: Profile tests and document slow cases with fixes
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
argument-hint: [package | path]
last_modified: 2026-01-31
source: planning-draft
---

read and run `ace-bundle wfi://test-performance-audit`
