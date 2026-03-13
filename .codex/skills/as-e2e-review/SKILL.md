---
name: as-e2e-review
description: Deep exploration producing a coverage matrix of functionality, unit tests,
  and E2E tests
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Glob
- Grep
argument-hint: "<package> [--scope <scenario-id>]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/review
---

Load and run `mise exec -- ace-bundle wfi://e2e/review` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
