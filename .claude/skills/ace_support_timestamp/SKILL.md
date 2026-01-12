---
name: ace:timestamp
description: ENCODE and DECODE timestamps to/from compact Base36 IDs
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-timestamp:*)
  - Bash(ace-context:*)
  - Read
argument-hint: [encode|decode|config] [value] [options]
last_modified: 2026-01-09
source: ace-support-timestamp
---

read and run `ace-context wfi://timestamp`
