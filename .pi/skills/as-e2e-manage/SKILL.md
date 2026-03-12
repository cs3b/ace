---
name: as-e2e-manage
description: Orchestrate the 3-stage E2E test lifecycle pipeline (review → plan →
  rewrite)
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
- Grep
- Skill
argument-hint: "<package> [--dry-run] [--run-tests]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/manage
---

read and run `ace-bundle wfi://e2e/manage`
