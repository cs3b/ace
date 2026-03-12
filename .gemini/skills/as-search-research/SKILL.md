---
name: as-search-research
description: RESEARCH codebases through planned multi-search analysis
user-invocable: true
allowed-tools:
- Bash(ace-search:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[goal] [--scope=path] [--depth=shallow|normal|deep]"
last_modified: 2026-01-09
source: ace-search
skill:
  kind: workflow
  execution:
    workflow: wfi://search/research
---

read and run `ace-bundle wfi://search/research`
