---
name: as-lint-run
description: Run ace-lint on project files with optional autofix and report
user-invocable: true
allowed-tools:
- Bash(ace-lint:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[file-pattern] [--fix] [--report]"
last_modified: 2026-03-10
source: ace-lint
skill:
  kind: workflow
  execution:
    workflow: wfi://lint/run
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://lint/run`
