---
name: as-b36ts
description: ENCODE and DECODE timestamps to/from compact Base36 IDs
# bundle: wfi://b36ts
# context: fork for codex
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-b36ts:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[encode|decode|config] [value] [options]"
last_modified: 2026-03-09
source: ace-b36ts
integration:
  providers:
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: capability
  execution:
    workflow: wfi://b36ts
---

read and run `ace-bundle wfi://b36ts`
