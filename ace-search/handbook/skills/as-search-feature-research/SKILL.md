---
name: as-search-feature-research
description: RESEARCH codebases to identify feature gaps and implementation patterns
# bundle: wfi://search/feature-research
# context: no-fork
# agent: Explore
user-invocable: true
allowed-tools:
  - Bash(ace-search:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[feature_description] [--scope=path] [--depth=shallow|normal|deep]"
last_modified: 2026-01-09
source: ace-search
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://search/feature-research
---

read and run `ace-bundle wfi://search/feature-research`
