---
id: v.0.9.0+task.179.10
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.179.02
parent: v.0.9.0+task.179
---

# Migrate ace-review to dry-cli

## Objective

Migrate ace-review CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Moderate
**Commands**: `review` (default)
**Options**: preset, task, subject, auto-execute, model

## Scope of Work

#### Modify

- `ace-review/lib/ace/review/cli.rb`
- `ace-review/ace-review.gemspec`
- `ace-review/CHANGELOG.md`

## Implementation Plan

- [x] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [x] Convert cli.rb to dry-cli Registry
- [x] Add dry-cli dependency
- [x] Run tests: `ace-test ace-review`
- [x] Verify: `ace-review --preset pr --help`, `ace-review --help`
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
