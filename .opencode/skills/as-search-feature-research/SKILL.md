---
name: as-search-feature-research
description: RESEARCH codebases to identify feature gaps and implementation patterns
user-invocable: true
allowed-tools:
- Bash(ace-search:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[feature_description] [--scope=path] [--depth=shallow|normal|deep]"
last_modified: 2026-01-09
source: ace-search
skill:
  kind: workflow
  execution:
    workflow: wfi://search/feature-research
---

Load and run `ace-bundle wfi://search/feature-research` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
