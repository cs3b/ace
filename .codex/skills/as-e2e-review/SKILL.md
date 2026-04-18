---
name: as-e2e-review
description: Review E2E coverage for modified packages and run targeted package scenarios
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Glob
- Grep
argument-hint: "<package> [--scope <scenario-id>]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
assign:
  source: wfi://e2e/review
  steps:
  - name: verify-e2e
    description: Review E2E coverage for modified packages and run targeted package
      scenarios
    tags:
    - testing
    - e2e
    - verification
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/review
---

Load and run `ace-bundle wfi://e2e/review` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
