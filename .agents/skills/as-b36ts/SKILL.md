---
name: as-b36ts
description: ENCODE and DECODE timestamps to/from compact Base36 IDs
user-invocable: true
allowed-tools:
- Bash(ace-b36ts:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[encode|decode|config] [value] [options]"
last_modified: 2026-03-09
source: ace-b36ts
skill:
  kind: capability
  execution:
    workflow: wfi://b36ts
---

Load and run `ace-bundle wfi://b36ts` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
