---
name: as-lint-run
description: Run ace-lint on project files with optional autofix and report
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-lint:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[file-pattern] [--fix] [--report]"
source: ace-lint
---

read and run `ace-bundle wfi://lint/run`
