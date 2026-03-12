---
name: as-demo-create
description: Create or update VHS demo tapes from shell commands
user-invocable: true
allowed-tools:
- Bash(ace-demo:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "<name> [--force] -- <commands...>"
last_modified: 2026-03-05
source: ace-demo
skill:
  kind: workflow
  execution:
    workflow: wfi://demo/create
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://demo/create`
