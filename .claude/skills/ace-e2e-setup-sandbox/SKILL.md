---
name: ace-e2e-setup-sandbox
description: Standardized sandbox setup for safe E2E tests with external APIs
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-nav:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [test-id | scenario]
last_modified: 2026-02-01
source: ace-test-runner-e2e
---

read and run `ace-bundle wfi://e2e/setup-sandbox`
