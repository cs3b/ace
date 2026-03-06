---
name: as-lint-process-report
description: Process lint report and create tasks for manual fixes
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [report-path]
source: ace-lint
---

read and run `ace-bundle wfi://lint/process-report`
