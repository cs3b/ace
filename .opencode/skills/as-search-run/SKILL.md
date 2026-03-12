---
name: as-search-run
description: SEARCH code patterns and files - intelligent discovery
user-invocable: true
allowed-tools:
- Bash(ace-search:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[pattern] [--file|--content] [options]"
last_modified: 2026-01-09
source: ace-search
skill:
  kind: workflow
  execution:
    workflow: wfi://search/run
---

read and run `ace-bundle wfi://search/run`
