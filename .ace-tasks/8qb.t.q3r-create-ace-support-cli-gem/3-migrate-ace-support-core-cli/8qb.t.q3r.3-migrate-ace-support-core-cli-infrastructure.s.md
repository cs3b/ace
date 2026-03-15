---
id: 8qb.t.q3r.3
status: done
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
- **Input**: ace-support-core's CLI infrastructure currently wrapping dry-cli with monkey-patches and workarounds.
- **Process**: Replace dry-cli dependency in ace-support-core with ace-support-cli. Create new `Ace::Core::CLI::Base` module replacing `Ace::Core::CLI::DryCli::Base`. Delete all monkey-patch files, `ArgvCoalescer`, and `convert_types()`. Delete old `dry_cli/` directory entirely.
- **Output**: ace-support-core depends on ace-support-cli instead of dry-cli. Old `dry_cli/` directory and all its files are deleted. New `Ace::Core::CLI::Base` module at new require path.

### Expected Behavior

ace-support-core currently wraps dry-cli with 13 infrastructure files:
1. `base.rb` — Core module with STANDARD_OPTIONS, helpers, `convert_types()`, `validate_required!()`, error handling.
2. `help_formatter.rb` — Monkey-patches `Dry::CLI::Banner` for ALL-CAPS help.
3. `usage_formatter.rb` — Monkey-patches `Dry::CLI::Usage` for registry help.
4. `help_concise.rb` — Concise `-h` formatter.
5. `argv_coalescer.rb` — ARGV preprocessing for array options.
6. `version_command.rb` — Version command factory.
7. `help_command.rb` — Help command factory.

The migration (per ADR-024 — no backward compatibility pre-1.0.0):
1. **Replace dry-cli gemspec dependency** with ace-support-cli in ace-support-core.
2. **Create new Base module**: New `Ace::Core::CLI::Base` at `lib/ace/core/cli/base.rb` inheriting from `Ace::Support::Cli::Command`. Keep all helper methods (verbose?, quiet?, debug?, debug_log, raise_cli_error, validate_required!, format_pairs). Keep STANDARD_OPTIONS and RESERVED_FLAGS.
3. **Delete convert_types() entirely**: Type coercion is now handled by the parser. No deprecation warning — method is removed. All current callers (6 commands across 5 gems) use it only for option values.
4. **Delete ArgvCoalescer entirely**: Array accumulation is now native. No deprecation warning — file is removed.
5. **Delete monkey-patch files**: `help_formatter.rb` and `usage_formatter.rb` are replaced by ace-support-cli's native help system.
6. **Delegate help components**: `HelpCommand.build()`, `VersionCommand.build()`, `HelpConcise` delegate to ace-support-cli equivalents.
7. **Delete old dry_cli/ directory**: The entire `lib/ace/core/cli/dry_cli/` directory is removed. No require path shims. Old paths break immediately (ADR-024).

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
require "ace/core/cli/base"

class MyCommand < Ace::Support::Cli::Command
  include Ace::Core::CLI::Base

  option :timeout, type: :integer, default: 30
  def call(timeout:, **)
    # timeout is already Integer — no convert_types needed
  end
end
```

**Error Handling:**
- `require "ace/core/cli/dry_cli/base"` raises `LoadError` immediately (no shim — per ADR-024).
- `convert_types()` is deleted — callers that weren't updated in this subtask fail at runtime with `NoMethodError` (caught by subtask 4 migration).

**Edge Cases:**
- `STANDARD_OPTIONS` and `RESERVED_FLAGS` constants remain unchanged.
- Helper methods (verbose?, quiet?, debug?, etc.) are preserved in the new Base module unchanged.

### Success Criteria

- [x] **dry-cli removed from ace-support-core**: gemspec depends on ace-support-cli, not dry-cli.
- [x] **New Base module created**: `Ace::Core::CLI::Base` at `lib/ace/core/cli/base.rb`, inherits from `Ace::Support::Cli::Command`, all helpers preserved.
- [ ] **Old dry_cli/ directory deleted**: entire `lib/ace/core/cli/dry_cli/` removed — no shims, no aliases (ADR-024).
- [x] **ArgvCoalescer deleted**: file removed entirely.
- [x] **convert_types() deleted**: method removed entirely.
- [x] **ace-support-core tests updated and pass**: tests reference new paths and module names.
- [ ] **Help output unchanged**: verified via diff comparison.

### Validation Questions

- [ ] **Should old require paths break?** -> Yes. Per ADR-024, no require path shims for pre-1.0.0 gems. Old paths break immediately; subtask 4 updates all consumers.
- [x] **Should convert_types be removed or deprecated?** -> Removed entirely. Research confirmed all 6 callers use it only for option values (no non-option uses exist). ADR-024 prohibits deprecation warnings.
- [x] **Should Base module be renamed?** -> Yes. New module `Ace::Core::CLI::Base` at `lib/ace/core/cli/base.rb`. Old `Ace::Core::CLI::DryCli::Base` is deleted with no alias.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask
- **Slice Outcome**: ace-support-core depends on ace-support-cli instead of dry-cli, with monkey-patches deleted and old dry_cli/ directory removed entirely (no shims per ADR-024).
- **Advisory Size**: medium
- **Context Dependencies**: subtask 1 (gem core), subtask 2 (help system), current base.rb and monkey-patch files

### Verification Plan

#### Unit / Component Validation
- [ ] Base module helpers (verbose?, quiet?, debug?, debug_log, raise_cli_error, validate_required!, format_pairs) work unchanged.
- [ ] STANDARD_OPTIONS and RESERVED_FLAGS constants are accessible via new path.
- [ ] `convert_types()` is absent — no method defined.
- [ ] `ArgvCoalescer` is absent — no file exists.

#### Integration / E2E Validation
- [ ] `ace-test ace-support-core` passes with updated tests.
- [ ] Help output from representative command matches pre-migration output.

#### Failure / Invalid-Path Validation
- [ ] `require "ace/core/cli/dry_cli/base"` raises `LoadError` (no shim).
- [ ] `require "ace/core/cli/base"` loads successfully.
- [ ] Old `lib/ace/core/cli/dry_cli/` directory does not exist.

#### Verification Commands
- [ ] `ace-test ace-support-core`
- [ ] `rg -n "require.*dry_cli" ace-support-core/`
- [ ] `rg -n "Dry::CLI" ace-support-core/`

## Objective

Replace dry-cli with ace-support-cli in ace-support-core, removing monkey-patches and workarounds while preserving all helper methods. Old require paths and modules are deleted without shims per ADR-024.

## Scope of Work

- **User Experience Scope**: ace-support-core's CLI infrastructure is cleanly replaced. Downstream gems break until migrated in subtask 4.
- **System Behavior Scope**: Swap dependency, create new Base, delete old dry_cli/ directory, delete workarounds.
- **Interface Scope**: New require path `ace/core/cli/base`. Old paths deleted (ADR-024).

### Deliverables

#### Behavioral Specifications
- New `Ace::Core::CLI::Base` module on ace-support-cli
- Deleted monkey-patch files
- Deleted ArgvCoalescer and convert_types entirely
- Deleted old `dry_cli/` directory (no shims)

#### Validation Artifacts
- Test suite passing
- Help output diff comparison
- Require path verification

### Consumer Packages

- **ace-support-core**: the gem being migrated
- **All ~27 downstream gems**: consume ace-support-core's Base module

## Out of Scope

- ❌ Migrating downstream gems (subtask 4)
- ❌ Changing Base module's public helper interface (helpers preserved, only base class and require path change)

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- Depends on: 8qb.t.q3r.1 (gem core), 8qb.t.q3r.2 (help system)
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb`
- `ace-support-core/lib/ace/core/cli/error.rb`
