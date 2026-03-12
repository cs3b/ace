---
id: 8qb.t.q3r
status: draft
priority: high
created_at: "2026-03-12 17:24:10"
estimate: TBD
dependencies: []
tags: [cli, dependency, support, infrastructure]
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/base.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb, ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb, ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_command.rb, ace-support-core/lib/ace/core/cli/error.rb, docs/decisions/ADR-023-dry-cli-framework.md, docs/ace-gems.g.md, ace-handbook/handbook/guides/cli-dry-cli.g.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/0-spike-validate-optionparser-based-cli/8qb.t.q3r.0-spike-validate-optionparser-based-cli-framework.s.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/1-build-ace-support-cli-gem/8qb.t.q3r.1-build-ace-support-cli-gem-core.s.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/2-build-ace-support-cli-help/8qb.t.q3r.2-build-ace-support-cli-help-system.s.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/3-migrate-ace-support-core-cli/8qb.t.q3r.3-migrate-ace-support-core-cli-infrastructure.s.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/4-migrate-downstream-gems-and-remove/8qb.t.q3r.4-migrate-downstream-gems-and-remove-dry-cli.s.md, .ace-tasks/8qb.t.q3r-create-ace-support-cli-gem/ux/usage.md]
  commands: []
needs_review: false
---

# Create ace-support-cli gem to replace dry-cli

## Behavioral Specification

### User Experience
- **Input**: CLI command authors define commands using `Ace::Support::Cli::Command` with `desc`, `option`, `argument`, `example`, and `register` — the same DSL shape as dry-cli.
- **Process**: Options declared with `type: :integer`, `:float`, or `:boolean` are automatically coerced by the parser before reaching `call()`. Array options accumulate from repeated flags natively. No monkey-patches, no `convert_types()`, no `ArgvCoalescer`.
- **Output**: All ~103 CLI commands across ~27 gems work identically to today but with correct types, and dry-cli is removed from the dependency tree.

### Expected Behavior

dry-cli has recurring friction across the monorepo:
- `type: :integer` options arrive as strings, requiring manual `convert_types()` or `.to_i` in every command
- Limited option validation (no required options enforcement, no allowed-values at parse time)
- Array options overwrite instead of accumulate on repeated flags (requires ArgvCoalescer workaround)
- Type coercion bugs propagate to downstream libraries (strings passed to Faraday where integers/floats expected)

The replacement `ace-support-cli` gem provides:
1. **Command base class** with identical DSL to dry-cli (`desc`, `option`, `argument`, `example`).
2. **Parser** built on Ruby's stdlib `OptionParser` with automatic type coercion — integers arrive as `Integer`, floats as `Float`, booleans as `true`/`false`.
3. **Registry** for multi-command CLIs with subcommand routing.
4. **Runner** as the entry point replacing `Dry::CLI.new(registry).call`.
5. **Native array accumulation** from repeated `--flag val1 --flag val2` without preprocessing.
6. **Help system** porting the current monkey-patched `Banner`, `Usage`, `HelpConcise`, `HelpCommand`, and `VersionCommand` into native implementations with identical output.

This parent task is an orchestrator coordinating five vertical slices:
- `8qb.t.q3r.0` spikes the OptionParser approach end-to-end
- `8qb.t.q3r.1` builds the gem core (Command, Registry, Parser, Runner)
- `8qb.t.q3r.2` builds the help system (Banner, Usage, HelpConcise, HelpCommand, VersionCommand)
- `8qb.t.q3r.3` migrates ace-support-core CLI infrastructure
- `8qb.t.q3r.4` migrates all downstream gems and removes dry-cli

### Interface Contract

```ruby
# New command definition (identical DSL to dry-cli)
module Ace
  module Support
    module Cli
      class Command
        def self.desc(text) = ...
        def self.option(name, type:, default: nil, desc: "", aliases: [], values: nil, required: false) = ...
        def self.argument(name, type: :string, required: true, desc: "") = ...
        def self.example(lines) = ...
      end
    end
  end
end
```

```ruby
# Before (dry-cli): types are wrong
class MyCommand < Dry::CLI::Command
  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :tags, type: :array, desc: "Tags to apply"

  def call(timeout:, tags:, **)
    timeout.class  # => String (BUG: "30" not 30)
    tags           # => only last --tags value (BUG: overwrites)
  end
end
```

```ruby
# After (ace-support-cli): types are correct
class MyCommand < Ace::Support::Cli::Command
  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :tags, type: :array, desc: "Tags to apply"

  def call(timeout:, tags:, **)
    timeout.class  # => Integer (correct: 30)
    tags           # => ["a", "b"] (correct: accumulated)
  end
end
```

```ruby
# Registry and Runner (same pattern as dry-cli)
registry = Ace::Support::Cli::Registry.new
registry.register "lint", LintCommand
registry.register "test", version: "1.0" do |r|
  r.register "atoms", TestAtomsCommand
  r.register "molecules", TestMoleculesCommand
end

Ace::Support::Cli::Runner.new(registry).call
```

```ruby
# Exe entry point
#!/usr/bin/env ruby
require "ace/support/cli"
require "ace/my_tool/cli/registry"
Ace::Support::Cli::Runner.new(Ace::MyTool::CLI::Registry).call
```

**Error Handling:**
- Invalid integer values (e.g., `--timeout abc`) raise `Ace::Support::Cli::ParseError` with a user-friendly message.
- Missing required options raise `Ace::Support::Cli::ParseError` listing the missing flags.
- Unknown flags raise `Ace::Support::Cli::ParseError` suggesting close matches.

**Edge Cases:**
- `--` terminates option parsing; remaining args are positional.
- `--[no-]flag` toggles boolean options.
- Default values respect declared types (no string-wrapping of integer defaults).
- Hash options (`type: :hash`) parse `key:value` pairs (1 current usage).
- Float options parse with `Float()` strict coercion (1 current usage).

### Success Criteria

- [ ] **Type coercion works**: options declared `type: :integer` arrive as `Integer` in `call()`, `:float` as `Float`, `:boolean` as `true`/`false`.
- [ ] **Array accumulation works**: repeated `--flag val` accumulates into arrays natively.
- [ ] **DSL compatible**: `desc`, `option`, `argument`, `example`, `register` work identically to dry-cli.
- [ ] **Help output identical**: `--help` and `-h` produce the same formatted output as current monkey-patched dry-cli.
- [ ] **All commands migrated**: ~103 CLI command classes across ~27 gems use ace-support-cli.
- [ ] **dry-cli removed**: no gem in the monorepo depends on dry-cli.
- [ ] **convert_types eliminated**: no command uses `convert_types()` or manual `.to_i`/`.to_f` for option values.
- [ ] **ArgvCoalescer eliminated**: no command needs ARGV preprocessing for array options.

### Validation Questions

- [x] **Should ace-support-cli use OptionParser internally?** -> Yes, validated by spike (subtask 0). Kill criteria: pivot to wrapping dry-cli parser if OptionParser can't handle mixed positional+keyword args.
- [x] **Must the DSL be identical to dry-cli?** -> Yes, to keep migration mechanical.
- [x] **Should help output change?** -> No, must be identical to current formatted output.
- [x] **Is this a new gem or added to ace-support-core?** -> New gem: `ace-support-cli`. Keeps CLI parsing separable from core support utilities.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator
- **Slice Outcome**: dry-cli is replaced across the entire monorepo with a purpose-built ace-support-cli gem that solves type coercion, array accumulation, and help formatting natively.
- **Advisory Size**: large
- **Context Dependencies**: dry-cli DSL surface, 27 dependent gems, 103 command classes, 13 monkey-patch/wrapper files in ace-support-core

### Verification Plan

#### Unit / Component Validation
- [ ] Child slice `q3r.0` proves OptionParser handles all option types end-to-end.
- [ ] Child slice `q3r.1` validates Parser, Command, Registry, Runner in isolation.
- [ ] Child slice `q3r.2` validates help output matches current monkey-patched format.

#### Integration / E2E Validation
- [ ] Child slice `q3r.3` validates ace-support-core consumers work with new base module.
- [ ] Child slice `q3r.4` validates all downstream gems pass existing tests after migration.
- [ ] `ace-test-suite` passes with zero dry-cli references remaining.

#### Failure / Invalid-Path Validation
- [ ] Invalid option values produce user-friendly parse errors.
- [ ] Missing required options are caught at parse time, not in command logic.
- [ ] Unknown flags suggest close matches instead of silent failures.

#### Verification Commands
- [ ] `ace-test ace-support-cli`
- [ ] `ace-test ace-support-core`
- [ ] `ace-test-suite`
- [ ] `rg -n "dry.cli|Dry::CLI|convert_types|ArgvCoalescer" --type ruby`

## Objective

Replace dry-cli with a purpose-built ace-support-cli gem that provides automatic type coercion, native array accumulation, and integrated help formatting — eliminating monkey-patches and manual workarounds across the monorepo.

## Scope of Work

- **User Experience Scope**: Command authors use the same DSL but get correct types automatically.
- **System Behavior Scope**: New gem with Command, Registry, Parser, Runner, and help system. Migration of all consumers. Removal of dry-cli.
- **Interface Scope**: `Ace::Support::Cli` namespace replaces `Dry::CLI` namespace.

### Deliverables

#### Behavioral Specifications
- ace-support-cli gem with Command, Registry, Parser, Runner
- Help system: Banner, Usage, HelpConcise, HelpCommand, VersionCommand
- Migration of ace-support-core CLI infrastructure
- Migration of all downstream gems

#### Validation Artifacts
- Spike proof-of-concept
- Help output comparison (before/after)
- Full test suite passing with no dry-cli references

### Consumer Packages

- **ace-support-core**: primary consumer, adapts Base module to new gem
- **All ~27 gems with CLI commands**: swap base class and requires
- **32 executables**: update entry points

### Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| `Ace::Support::Cli::Command` | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Registry` | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Parser` | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Runner` | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Option` | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Argument` | 8qb.t.q3r.1 | -- | KEPT |
| Automatic type coercion | 8qb.t.q3r.1 | -- | KEPT |
| Native array accumulation | 8qb.t.q3r.1 | -- | KEPT |
| `Ace::Support::Cli::Banner` | 8qb.t.q3r.2 | -- | KEPT |
| `Ace::Support::Cli::Usage` | 8qb.t.q3r.2 | -- | KEPT |
| `Ace::Support::Cli::HelpConcise` | 8qb.t.q3r.2 | -- | KEPT |
| `Ace::Support::Cli::HelpCommand` | 8qb.t.q3r.2 | -- | KEPT |
| `Ace::Support::Cli::VersionCommand` | 8qb.t.q3r.2 | -- | KEPT |
| `Dry::CLI` dependency | legacy | 8qb.t.q3r.4 | REMOVED |
| `Dry::CLI::Banner` monkey-patch | legacy | 8qb.t.q3r.3 | REMOVED |
| `Dry::CLI::Usage` monkey-patch | legacy | 8qb.t.q3r.3 | REMOVED |
| `ArgvCoalescer` | legacy | 8qb.t.q3r.3 | REMOVED |
| `convert_types()` for options | legacy | 8qb.t.q3r.3 | REMOVED |
| Manual `.to_i`/`.to_f` in commands | legacy | 8qb.t.q3r.4 | REMOVED |

## Out of Scope

- ❌ Changing CLI command behavior or flags (migration is mechanical, not a redesign)
- ❌ Adding new CLI features beyond what dry-cli provided (except type coercion fix)
- ❌ Changing help output format (must match current output)
- ❌ Replacing non-CLI uses of dry-cli patterns (if any exist)
- ❌ Redesigning the `Ace::Core::CLI::DryCli::Base` module interface (only swap underlying dependency)

## References

- Idea: 8pr2ca — Create ace-support-cli Gem to Replace dry-cli Dependency
- Usage documentation: `ux/usage.md`
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_command.rb`
- `docs/decisions/ADR-023-dry-cli-framework.md`
