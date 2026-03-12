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

read and run `ace-bundle wfi://e2e/review`
