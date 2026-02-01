---
name: ace:setup-e2e-sandbox
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
source: ace-test-e2e-runner
---

read and run `ace-bundle wfi://setup-e2e-sandbox`
