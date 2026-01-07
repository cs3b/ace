---
id: v.0.9.0+task.179.11
status: done
priority: medium
estimate: 2h
dependencies:
  - v.0.9.0+task.179.02
parent: v.0.9.0+task.179
---

# Migrate ace-prompt to dry-cli

## Objective

Migrate ace-prompt CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Moderate
**Commands**: `process` (default), `setup`
**Options**: task, enhance, model, archive

## Scope of Work

#### Modify

- `ace-prompt/lib/ace/prompt/cli.rb`
- `ace-prompt/ace-prompt.gemspec`
- `ace-prompt/CHANGELOG.md`

## Implementation Plan

- [x] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [x] Convert cli.rb to dry-cli Registry
- [x] Add dry-cli dependency
- [x] Run tests: `ace-test ace-prompt`
- [x] Verify: `ace-prompt --help`, `ace-prompt setup --task 121`
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
