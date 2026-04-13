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
---

Load and run `ace-bundle wfi://demo/record` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

Treat demo verification as fail-closed:
- if recording verification reports `instruction_defect`, fix the tape/instructions and retry once
- if recording verification reports `product_bug` or `verification_error`, stop and return the generated report from `.ace-local/demo/`
