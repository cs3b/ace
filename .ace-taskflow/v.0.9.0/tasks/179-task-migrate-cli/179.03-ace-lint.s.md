---
id: v.0.9.0+task.179.03
status: done
priority: medium
estimate: 1.5h
dependencies:
- v.0.9.0+task.179.02
parent: v.0.9.0+task.179
worktree:
  branch: 179.03-migrate-ace-lint-to-dry-cli
  path: "../ace-task.179.03"
  created_at: '2026-01-07 16:08:36'
  updated_at: '2026-01-07 16:08:36'
---

# Migrate ace-lint to dry-cli

## Objective

Migrate ace-lint CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Simple (single default command)
**Commands**: `lint` (default)
**Options**: type, fix, quiet, verbose

## Scope of Work

#### Modify

- `ace-lint/lib/ace/lint/cli.rb` - Convert to dry-cli
- `ace-lint/ace-lint.gemspec` - Add dry-cli dependency
- `ace-lint/CHANGELOG.md`

## Implementation Plan

- [x] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [x] Convert cli.rb to dry-cli Registry
- [x] Add dry-cli dependency to gemspec
- [x] Run tests: `ace-test ace-lint`
- [x] Verify: `ace-lint --help`, `ace-lint file.md`, `ace-lint --fix file.md`
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