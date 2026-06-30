---
name: as-e2e-rewrite
description: Execute a change plan — delete, create, modify, and consolidate E2E tests
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
- Grep
- Skill
argument-hint: "<package> [--plan <path>] [--dry-run]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/rewrite
---

Load and run `ace-bundle wfi://e2e/rewrite` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
