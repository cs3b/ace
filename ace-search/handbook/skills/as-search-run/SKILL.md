---
name: as-search-run
description: SEARCH code patterns and files - intelligent discovery
# bundle: wfi://search/run
# context: fork for codex
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-search:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[pattern] [--file|--content] [options]"
last_modified: 2026-01-09
source: ace-search
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://search/run
---

read and run `ace-bundle wfi://search/run`
