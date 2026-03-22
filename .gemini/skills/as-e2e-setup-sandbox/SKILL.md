---
name: as-e2e-setup-sandbox
description: Standardized sandbox setup for safe E2E tests with external APIs
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
argument-hint:
- test-id | scenario
last_modified: 2026-02-01
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/setup-sandbox
---

Load and run `ace-bundle wfi://e2e/setup-sandbox` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
