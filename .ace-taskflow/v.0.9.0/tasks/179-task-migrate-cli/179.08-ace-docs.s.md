---
id: v.0.9.0+task.179.08
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.179.02
parent: v.0.9.0+task.179
---

# Migrate ace-docs to dry-cli

## Objective

Migrate ace-docs CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Moderate
**Commands**: `status`, `update`, `diff`, `validate`
**Options**: needs-update, set, format

## Scope of Work

#### Modify

- `ace-docs/lib/ace/docs/cli.rb`
- `ace-docs/ace-docs.gemspec`
- `ace-docs/CHANGELOG.md`

## Implementation Plan

- [x] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [x] Convert cli.rb to dry-cli Registry
- [x] Add dry-cli dependency
- [x] Run tests: `ace-test ace-docs`
- [x] Verify: `ace-docs status`, `ace-docs --help`
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
