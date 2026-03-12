---
name: as-demo-record
description: Record terminal demos from VHS tapes or inline commands
user-invocable: true
allowed-tools:
- Bash(ace-demo:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "<tape|name> [--pr <number>] [-- commands...]"
last_modified: 2026-03-05
source: ace-demo
skill:
  kind: workflow
  execution:
    workflow: wfi://demo/record
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://demo/record`
