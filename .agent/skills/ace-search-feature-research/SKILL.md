---
name: ace-search-feature-research
description: RESEARCH codebases to identify feature gaps and implementation patterns
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
---

read and run `ace-bundle wfi://search/feature-research`
