---
name: as-e2e-create
description: Create a new E2E test scenario from template
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
- Grep
argument-hint: "<package> <area> [--context <description>]"
last_modified: 2026-01-19
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/create
---

Load and run `mise exec -- ace-bundle wfi://e2e/create` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
