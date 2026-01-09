---
id: v.0.9.0+task.157.18
status: done
priority: medium
estimate: 2h
dependencies:
- v.0.9.0+task.157.11
parent: v.0.9.0+task.157
worktree:
  branch: 157.18-ace-docs-migrate-documentregistry-to-ace-config
  path: "../ace-task.157.18"
  created_at: '2026-01-01 21:08:43'
  updated_at: '2026-01-01 21:08:43'
---

# ace-docs - Migrate DocumentRegistry to ace-config

## Objective

Complete ace-config migration in ace-docs by:
1. Migrating DocumentRegistry from manual YAML loading to ace-config
2. Making Document model read freshness thresholds from config instead of hardcoded values

## Current Issues

- `organisms/document_registry.rb` (lines 130-139, 195-201) uses custom YAML loading with manual cascade search
- `models/document.rb` (lines 118-158) has hardcoded freshness thresholds (30, 45, 7, 14 days)
- Config has `default_freshness_days` but Document model doesn't read from it

## Scope of Work

### Files to Modify

- `ace-docs/lib/ace/docs/organisms/document_registry.rb` - Use ace-config instead of manual YAML loading
- `ace-docs/lib/ace/docs/models/document.rb` - Read freshness thresholds from config

## Implementation Plan

### Execution Steps

- [x] Refactor DocumentRegistry to use `Ace::Config.resolve_namespace("docs")`
  > Remove custom YAML loading logic (lines 101-139)
  > Replace with Ace::Docs.config access pattern

- [x] Update Document model to get freshness thresholds from config
  > Replace hardcoded values in freshness_status method
  > Use Ace::Docs.config["default_freshness_days"]

- [x] Run tests with `ace-test ace-docs`

- [x] Bump patch version in ace-docs/lib/ace/docs/version.rb

## Acceptance Criteria

- [x] DocumentRegistry uses ace-config for configuration loading
- [x] Document model reads freshness thresholds from .ace-defaults/docs/config.yml
- [x] All ace-docs tests pass
- [x] Gem version bumped
