---
name: ace:e2e-sandbox-setup
description: Standardized sandbox setup for safe E2E tests
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
argument-hint: [test-id]
last_modified: 2026-01-31
source: planning-draft
---

read and run `ace-bundle wfi://e2e-sandbox-setup`
