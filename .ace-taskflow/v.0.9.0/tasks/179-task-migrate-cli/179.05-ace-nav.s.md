---
id: v.0.9.0+task.179.05
status: done
priority: medium
estimate: 2h
dependencies:
- v.0.9.0+task.179.02
parent: v.0.9.0+task.179
---

# Migrate ace-nav to dry-cli

## Objective

Migrate ace-nav CLI from Thor to dry-cli.

## CLI Analysis

**Complexity**: Moderate
**Commands**: `navigate` (default), `sources`
**Options**: list, sources, format

## Scope of Work

#### Modify

- `ace-nav/lib/ace/nav/cli.rb`
- `ace-nav/ace-nav.gemspec`
- `ace-nav/CHANGELOG.md`

## Implementation Plan

- [ ] Use infrastructure from 179.01:
  - `require "ace/core/cli/dry_cli/base"` for base patterns
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display
  - `Ace::Core::CLI::DryCli::VersionCommand` for version handling
- [ ] Convert cli.rb to dry-cli Registry
- [ ] Add dry-cli dependency
- [ ] Run tests: `ace-test ace-nav`
- [ ] Verify: `ace-nav wfi://commit`, `ace-nav --sources`
- [ ] Update CHANGELOG

## Acceptance Criteria

- [ ] All tests pass
- [ ] CLI behavior identical

## Migration Reference

See [docs/ace-gems.g.md#dry-cli-migration-gotchas](../../../../docs/ace-gems.g.md#dry-cli-migration-gotchas) for:
- Type Conversion (numeric options)
- Default Command Routing (CLI.start pattern)
- Help Documentation (desc + example)
- Boolean Options behavior