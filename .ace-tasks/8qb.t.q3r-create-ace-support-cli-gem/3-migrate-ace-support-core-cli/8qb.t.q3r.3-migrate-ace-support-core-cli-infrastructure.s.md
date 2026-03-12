---
id: 8qb.t.q3r.3
status: draft
priority: medium
created_at: "2026-03-12 17:25:44"
estimate: Medium
dependencies: [8qb.t.q3r.1, 8qb.t.q3r.2]
tags: [cli, migration, support-core]
parent: 8qb.t.q3r
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/base.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb, ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb, ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_command.rb, ace-support-core/lib/ace/core/cli/error.rb]
  commands: []
needs_review: false
---

# Migrate ace-support-core CLI infrastructure

## Behavioral Specification

### User Experience
- **Input**: Existing `require` paths and module inclusions in downstream gems continue working unchanged.
- **Process**: Replace dry-cli dependency in ace-support-core with ace-support-cli. Adapt the `Ace::Core::CLI::DryCli::Base` module to delegate to ace-support-cli internals. Remove monkey-patch files. Deprecate `ArgvCoalescer` and `convert_types()` for option values.
- **Output**: ace-support-core depends on ace-support-cli instead of dry-cli. All existing `require` paths continue working. Monkey-patch files are removed.

### Expected Behavior

ace-support-core currently wraps dry-cli with 13 infrastructure files:
1. `base.rb` — Core module with STANDARD_OPTIONS, helpers, `convert_types()`, `validate_required!()`, error handling.
2. `help_formatter.rb` — Monkey-patches `Dry::CLI::Banner` for ALL-CAPS help.
3. `usage_formatter.rb` — Monkey-patches `Dry::CLI::Usage` for registry help.
4. `help_concise.rb` — Concise `-h` formatter.
5. `argv_coalescer.rb` — ARGV preprocessing for array options.
6. `version_command.rb` — Version command factory.
7. `help_command.rb` — Help command factory.

The migration:
1. **Replace dry-cli gemspec dependency** with ace-support-cli in ace-support-core.
2. **Adapt Base module**: Change the base class from `Dry::CLI::Command` to `Ace::Support::Cli::Command`. Keep all helper methods (verbose?, quiet?, debug?, debug_log, raise_cli_error, validate_required!, format_pairs). Keep STANDARD_OPTIONS and RESERVED_FLAGS.
3. **Remove convert_types() for option values**: Type coercion is now handled by the parser. The method may be kept with a deprecation warning or adapted to handle only non-option coercions (if any exist). Commands using `convert_types()` or manual `.to_i`/`.to_f` for option values are updated.
4. **Remove ArgvCoalescer**: Array accumulation is now native. Deprecate with a warning or remove entirely.
5. **Remove monkey-patch files**: `help_formatter.rb` and `usage_formatter.rb` are replaced by ace-support-cli's native help system.
6. **Delegate help components**: `HelpCommand.build()`, `VersionCommand.build()`, `HelpConcise` delegate to ace-support-cli equivalents.
7. **Preserve require paths**: `require "ace/core/cli/dry_cli/base"` continues working (via shim or rename).

### Interface Contract

```ruby
# Before: downstream gems do this
require "ace/core/cli/dry_cli/base"

class MyCommand < Dry::CLI::Command
  include Ace::Core::CLI::DryCli::Base

  option :timeout, type: :integer, default: 30
  def call(timeout:, **)
    timeout = convert_types(timeout: timeout)[:timeout]  # manual coercion
  end
end
```

```ruby
# After: downstream gems do this (subtask 4 handles the migration)
require "ace/core/cli/base"  # new path (old path still works via shim)

class MyCommand < Ace::Support::Cli::Command
  include Ace::Core::CLI::Base

  option :timeout, type: :integer, default: 30
  def call(timeout:, **)
    # timeout is already Integer — no convert_types needed
  end
end
```

```ruby
# Require path compatibility
require "ace/core/cli/dry_cli/base"  # still works (shim to new path)
require "ace/core/cli/base"          # new canonical path
```

**Error Handling:**
- `convert_types()` emits a deprecation warning when called for option values, then passes through (values are already typed).
- `ArgvCoalescer` emits a deprecation warning when called, then passes through (arrays already accumulate).
- Missing require paths fail with clear "did you mean?" messages.

**Edge Cases:**
- Commands that use `convert_types()` for non-option values (e.g., environment variables, config values) continue to work — only option-value coercion is deprecated.
- Commands that call `.to_i` on option values in their `call()` method still work (Integer.to_i returns self) but should be cleaned up in subtask 4.
- `STANDARD_OPTIONS` and `RESERVED_FLAGS` constants remain unchanged.

### Success Criteria

- [ ] **dry-cli removed from ace-support-core**: gemspec depends on ace-support-cli, not dry-cli.
- [ ] **Base module adapted**: inherits from `Ace::Support::Cli::Command`, all helpers preserved.
- [ ] **Monkey-patches removed**: help_formatter.rb and usage_formatter.rb deleted.
- [ ] **ArgvCoalescer deprecated**: emits warning or removed entirely.
- [ ] **convert_types deprecated for options**: emits warning, option values arrive pre-typed.
- [ ] **Require paths preserved**: `require "ace/core/cli/dry_cli/base"` still works.
- [ ] **ace-support-core tests pass**: all existing tests green.
- [ ] **Help output unchanged**: verified via diff comparison.

### Validation Questions

- [x] **Should old require paths break?** -> No, provide shims for backwards compatibility during migration window.
- [x] **Should convert_types be removed or deprecated?** -> Deprecated for option values. It may still be useful for non-option coercions.
- [x] **Should Base module be renamed?** -> The module adapts to new internals. Namespace can be updated but old name must work via shim.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask
- **Slice Outcome**: ace-support-core depends on ace-support-cli instead of dry-cli, with monkey-patches removed and backwards-compatible require paths.
- **Advisory Size**: medium
- **Context Dependencies**: subtask 1 (gem core), subtask 2 (help system), current base.rb and monkey-patch files

### Verification Plan

#### Unit / Component Validation
- [ ] Base module helpers (verbose?, quiet?, debug?, debug_log, raise_cli_error, validate_required!, format_pairs) work unchanged.
- [ ] STANDARD_OPTIONS and RESERVED_FLAGS constants are accessible.
- [ ] Deprecated convert_types() emits warning and passes through.
- [ ] Deprecated ArgvCoalescer emits warning and passes through.

#### Integration / E2E Validation
- [ ] `ace-test ace-support-core` passes.
- [ ] Representative downstream gem (pick one) works with adapted ace-support-core.
- [ ] Help output from representative command matches pre-migration output.

#### Failure / Invalid-Path Validation
- [ ] Old require paths load successfully via shims.
- [ ] New require paths load successfully.
- [ ] Missing files produce clear error messages.

#### Verification Commands
- [ ] `ace-test ace-support-core`
- [ ] `rg -n "require.*dry_cli" ace-support-core/`
- [ ] `rg -n "Dry::CLI" ace-support-core/`

## Objective

Replace dry-cli with ace-support-cli in ace-support-core, removing monkey-patches and workarounds while preserving all helper methods and require paths for downstream consumers.

## Scope of Work

- **User Experience Scope**: Downstream gems see no breaking changes during migration window.
- **System Behavior Scope**: Swap dependency, adapt Base, remove monkey-patches, deprecate workarounds.
- **Interface Scope**: New require paths with shims for old paths.

### Deliverables

#### Behavioral Specifications
- Adapted Base module on ace-support-cli
- Removed monkey-patch files
- Deprecated ArgvCoalescer and convert_types
- Require path shims

#### Validation Artifacts
- Test suite passing
- Help output diff comparison
- Require path verification

### Consumer Packages

- **ace-support-core**: the gem being migrated
- **All ~27 downstream gems**: consume ace-support-core's Base module

## Out of Scope

- ❌ Migrating downstream gems (subtask 4)
- ❌ Changing Base module's public interface
- ❌ Removing non-option uses of convert_types

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- Depends on: 8qb.t.q3r.1 (gem core), 8qb.t.q3r.2 (help system)
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb`
- `ace-support-core/lib/ace/core/cli/error.rb`
