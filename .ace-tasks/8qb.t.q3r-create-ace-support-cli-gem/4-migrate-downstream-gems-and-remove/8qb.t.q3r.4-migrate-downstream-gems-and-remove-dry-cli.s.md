---
id: 8qb.t.q3r.4
status: draft
priority: medium
created_at: "2026-03-12 17:25:45"
estimate: Large
dependencies: [8qb.t.q3r.3]
tags: [cli, migration, downstream, dry-cli]
parent: 8qb.t.q3r
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/base.rb, docs/decisions/ADR-023-dry-cli-framework.md, docs/ace-gems.g.md, ace-handbook/handbook/guides/cli-dry-cli.g.md]
  commands: []
needs_review: false
---

# Migrate downstream gems and remove dry-cli

## Behavioral Specification

### User Experience
- **Input**: ~19 downstream gems with CLI commands currently using `Dry::CLI::Command` and `include Ace::Core::CLI::DryCli::Base`.
- **Process**: For each gem: swap base class to `Ace::Support::Cli::Command`, update requires, update exe entry points, remove `convert_types()` calls for option values, remove manual `.to_i`/`.to_f` for option values, run tests. Then remove dry-cli from the dependency tree entirely. Update documentation.
- **Output**: All CLI commands across the monorepo use ace-support-cli. dry-cli is fully removed. Documentation reflects the new framework.

### Expected Behavior

This subtask is mechanical, repetitive migration across ~19 gems with ~103 command classes and ~32 executables. The pattern for each gem is:

1. **Update gemspec**: Replace `dry-cli` dependency with `ace-support-cli` (if direct), or rely on transitive dependency through ace-support-core.
2. **Update requires**: Change `require "dry/cli"` to `require "ace/support/cli"`.
3. **Update base class**: Change `< Dry::CLI::Command` to `< Ace::Support::Cli::Command`.
4. **Update module include**: Change `include Ace::Core::CLI::DryCli::Base` to `include Ace::Core::CLI::Base` (new path from subtask 3).
5. **Remove convert_types calls**: Delete `convert_types()` invocations for option values (types are now correct).
6. **Remove manual .to_i/.to_f**: Delete manual integer/float coercion on option values (already typed).
7. **Update exe entry points**: Change `Dry::CLI.new(registry).call` to `Ace::Support::Cli::Runner.new(registry).call`.
8. **Run tests**: Verify all existing tests pass.

After all gems are migrated:
9. **Remove dry-cli from Gemfile/gemspec**: Remove all remaining dry-cli references.
10. **Remove require path shims**: Once all consumers use new paths, shims from subtask 3 can be removed.
11. **Update ADR-023**: Document the migration from dry-cli to ace-support-cli, rationale, and new architecture.
12. **Update handbook guide**: Rename/update `cli-dry-cli.g.md` to reflect ace-support-cli.
13. **Update docs/ace-gems.g.md**: Add ace-support-cli to gem listing.

### Interface Contract

```ruby
# Per-gem migration pattern (mechanical find-and-replace)

# requires: before → after
require "dry/cli"                       → require "ace/support/cli"
require "ace/core/cli/dry_cli/base"     → require "ace/core/cli/base"

# base class: before → after
class MyCmd < Dry::CLI::Command         → class MyCmd < Ace::Support::Cli::Command

# module: before → after
include Ace::Core::CLI::DryCli::Base    → include Ace::Core::CLI::Base

# exe entry: before → after
Dry::CLI.new(registry).call             → Ace::Support::Cli::Runner.new(registry).call

# remove these lines entirely:
timeout = convert_types(timeout: timeout)[:timeout]
count = options[:count].to_i
rate = options[:rate].to_f
```

```bash
# Verification per gem
ace-test <gem-name>

# Final verification
ace-test-suite
rg -n "dry.cli|Dry::CLI|convert_types|ArgvCoalescer" --type ruby
# Expected: zero matches
```

**Error Handling:**
- If a gem's tests fail after migration, investigate the specific command — likely a non-standard dry-cli usage pattern.
- If a require path is missed, the shim from subtask 3 catches it with a deprecation warning.
- If `convert_types` is used for non-option values (env vars, config), preserve those calls.

**Edge Cases:**
- Gems that directly depend on dry-cli (not via ace-support-core) need gemspec updates.
- Gems with custom `Dry::CLI` subclasses or direct `Dry::CLI::Registry` usage need individual attention.
- Test files that reference `Dry::CLI` classes need updating.
- `convert_types` calls that coerce non-option values (e.g., environment variables read as strings) should be preserved.

### Success Criteria

- [ ] **All ~19 downstream gems migrated**: base class, requires, exe entry points updated.
- [ ] **All tests pass**: `ace-test-suite` green.
- [ ] **dry-cli fully removed**: zero references to `dry-cli`, `Dry::CLI`, `convert_types` (for options), or `ArgvCoalescer` in any Ruby file.
- [ ] **ADR-023 updated**: documents migration rationale and new architecture.
- [ ] **Handbook guide updated**: reflects ace-support-cli instead of dry-cli.
- [ ] **ace-gems.g.md updated**: lists ace-support-cli.
- [ ] **No behavioral regressions**: all CLI commands work identically.

### Validation Questions

- [x] **Can migration be batched?** -> Yes, gems can be migrated in waves. Shims ensure partial migration works.
- [x] **Should convert_types be fully removed?** -> Remove for option values. Preserve for non-option coercions if they exist.
- [x] **Should require path shims be removed?** -> Yes, after all gems are migrated in this subtask.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask
- **Slice Outcome**: All CLI gems use ace-support-cli, dry-cli is removed from the dependency tree, documentation updated.
- **Advisory Size**: large (mechanical)
- **Context Dependencies**: subtask 3 (ace-support-core migrated), all downstream gem codebases

### Verification Plan

#### Unit / Component Validation
- [ ] Each migrated gem's tests pass individually: `ace-test <gem>`.
- [ ] No gem retains `Dry::CLI` references in source files.

#### Integration / E2E Validation
- [ ] `ace-test-suite` passes with all gems migrated.
- [ ] Representative CLI commands produce correct output end-to-end.
- [ ] Help output from representative commands matches pre-migration output.

#### Failure / Invalid-Path Validation
- [ ] `rg -n "dry.cli|Dry::CLI" --type ruby` returns zero matches.
- [ ] `rg -n "convert_types" --type ruby` returns zero matches for option-value usage.
- [ ] `rg -n "ArgvCoalescer" --type ruby` returns zero matches.

#### Verification Commands
- [ ] `ace-test-suite`
- [ ] `rg -n "dry.cli|Dry::CLI|convert_types|ArgvCoalescer" --type ruby`
- [ ] `ace-test ace-support-cli`
- [ ] `ace-test ace-support-core`

## Objective

Complete the monorepo migration from dry-cli to ace-support-cli by mechanically updating all downstream gems and removing dry-cli from the dependency tree entirely.

## Scope of Work

- **User Experience Scope**: All CLI commands work identically after migration.
- **System Behavior Scope**: ~19 gems migrated, dry-cli removed, documentation updated.
- **Interface Scope**: New require paths and base class throughout monorepo.

### Deliverables

#### Behavioral Specifications
- Migration of ~19 gems (~103 command classes, ~32 executables)
- Removal of dry-cli from dependency tree
- Updated ADR-023, handbook guide, ace-gems.g.md

#### Validation Artifacts
- Per-gem test results
- Full test suite results
- Zero dry-cli references grep verification

### Consumer Packages

- **All ~19 downstream gems**: migrated in this subtask
- **Documentation**: ADR-023, handbook, ace-gems.g.md

## Out of Scope

- ❌ Changing any command's behavior, flags, or output
- ❌ Adding new CLI features during migration
- ❌ Refactoring command implementations beyond the mechanical swap

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- Depends on: 8qb.t.q3r.3 (ace-support-core migrated)
- `docs/decisions/ADR-023-dry-cli-framework.md`
- `docs/ace-gems.g.md`
- `ace-handbook/handbook/guides/cli-dry-cli.g.md`
