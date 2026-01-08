---
id: v.0.9.0+task.179.13
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.179.02
parent: v.0.9.0+task.179
---

# Migrate ace-llm to dry-cli

## Objective

Migrate ace-llm CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Moderate
**Commands**: `query` (default), `models`, `providers`
**Options**: model, system, format

## Scope of Work

#### Modify

- `ace-llm/lib/ace/llm/cli.rb`
- `ace-llm/ace-llm.gemspec`
- `ace-llm/CHANGELOG.md`

## Implementation Plan

- [x] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [x] Convert cli.rb to dry-cli Registry
- [x] Add dry-cli dependency
- [x] Run tests: `ace-test ace-llm`
- [x] Verify: `ace-llm-query --help`, `ace-llm-query list-providers`
- [x] Update CHANGELOG

## Acceptance Criteria

- [x] All tests pass
- [x] CLI behavior identical

## Migration Reference

See [docs/ace-gems.g.md#dry-cli-migration-gotchas](../../../../docs/ace-gems.g.md#dry-cli-migration-gotchas) for:
- Type Conversion (numeric options)
- Default Command Routing (CLI.start pattern)
- Help Documentation (desc + example)
- Boolean Options behavior
