---
name: as-lint-process-report
description: Process lint report and create tasks for manual fixes
user-invocable: true
allowed-tools:
- Bash(ace-lint:*)
- Bash(ace-bundle:*)
- Read
argument-hint:
- report-path
last_modified: 2026-03-10
source: ace-lint
skill:
  kind: workflow
  execution:
    workflow: wfi://lint/process-report
---

read and run `ace-bundle wfi://lint/process-report`
