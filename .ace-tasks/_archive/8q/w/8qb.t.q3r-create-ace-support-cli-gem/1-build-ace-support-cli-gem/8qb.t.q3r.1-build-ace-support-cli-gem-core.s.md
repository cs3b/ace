---
id: 8qb.t.q3r.1
status: done
priority: high
created_at: "2026-03-12 17:25:43"
estimate: Medium
dependencies: [8qb.t.q3r.0]
tags: [cli, gem, core, parser]
parent: 8qb.t.q3r
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/base.rb, ace-support-core/lib/ace/core/cli/dry_cli/argv_coalescer.rb]
  commands: []
needs_review: false
---

# Build ace-support-cli gem core

## Behavioral Specification

### User Experience
- **Input**: Command authors define CLI commands using `Ace::Support::Cli::Command` with the same `desc`, `option`, `argument`, `example` DSL as dry-cli.
- **Process**: The gem provides Command, Registry, Parser, Runner, Option, and Argument classes. The Parser uses OptionParser internally for automatic type coercion. The Registry supports multi-command CLIs with subcommand routing. The Runner wires ARGV through parsing to command execution.
- **Output**: A fully functional CLI framework gem (`ace-support-cli`) that can replace dry-cli's core parsing and routing with correct type handling.

### Expected Behavior

The gem core provides these components:
1. **Command**: Base class with `desc`, `option`, `argument`, `example` class-level DSL. Subclasses implement `call(**params)` receiving typed keyword arguments.
2. **Option**: Value object storing option metadata (name, type, default, desc, aliases, values, required). Types: `:string`, `:integer`, `:float`, `:boolean`, `:array`, `:hash`.
3. **Argument**: Value object storing positional argument metadata (name, type, required, desc). Supports required and optional positional args in declaration order.
4. **Parser**: Builds an `OptionParser` from a command's declared options and arguments. Coerces values automatically: `Integer()` for `:integer`, `Float()` for `:float`, `true`/`false` for `:boolean`, array accumulation for `:array`, `key:value` splitting for `:hash`.
5. **Registry**: Stores command-to-name mappings with nested subcommand support. Same API as `Dry::CLI` registry (`register "name", CommandClass`).
6. **Runner**: Entry point that resolves the command from ARGV via Registry, parses remaining args via Parser, and calls the command. Replaces `Dry::CLI.new(registry).call`.

### Interface Contract

```ruby
# Command definition
class Ace::Support::Cli::Command
  def self.desc(text)
  def self.option(name, type: :string, default: nil, desc: "", aliases: [], values: nil, required: false)
  def self.argument(name, type: :string, required: true, desc: "")
  def self.example(lines)
  def call(**params)  # Override in subclass
end
```

```ruby
# Registry
registry = Ace::Support::Cli::Registry.new
registry.register "lint", LintCommand
registry.register "test" do |r|
  r.register "atoms", TestAtomsCommand
  r.register "molecules", TestMoleculesCommand
end
```

```ruby
# Runner
Ace::Support::Cli::Runner.new(registry).call          # uses ARGV
Ace::Support::Cli::Runner.new(registry).call(args: %w[lint --timeout 30])  # explicit args
```

```ruby
# Type coercion contract
option :count,   type: :integer  # => Integer
option :rate,    type: :float    # => Float
option :verbose, type: :boolean  # => true/false
option :tags,    type: :array    # => Array<String>
option :headers, type: :hash     # => Hash<String,String>
option :name,    type: :string   # => String (default)
```

**Error Handling:**
- `Ace::Support::Cli::ParseError` for invalid option values, missing required options, unknown flags.
- `Ace::Support::Cli::CommandNotFoundError` when registry lookup fails.
- Parse errors include the flag name and expected type in the message.
- Unknown flags suggest close matches (Levenshtein or prefix matching).

**Edge Cases:**
- `--` ends option parsing; remaining tokens are positional arguments.
- `--[no-]flag` for boolean options.
- `--flag=value` and `--flag value` both work.
- Default values are returned as declared type (integer default `30` stays `Integer`).
- `nil` defaults for optional options remain `nil` (not coerced).
- Empty registry produces a helpful "no commands registered" message.

### Success Criteria

- [ ] **Command DSL works**: `desc`, `option`, `argument`, `example` match dry-cli's API.
- [ ] **Type coercion automatic**: all 6 types coerce correctly without manual conversion.
- [ ] **Array accumulation native**: repeated flags accumulate without preprocessing.
- [ ] **Registry routing works**: nested subcommands resolve from ARGV.
- [ ] **Runner wires everything**: ARGV → Registry → Parser → Command.call works end-to-end.
- [ ] **Gem structure valid**: standard gem layout, gemspec, requires.
- [ ] **Tests pass**: unit tests for Parser, Command, Registry, Runner, Option, Argument.

### Validation Questions

- [x] **Should the namespace be `Ace::Support::Cli`?** -> Yes, consistent with `ace-support-*` naming.
- [x] **Should Runner accept explicit args?** -> Yes, for testing and programmatic use.
- [x] **Should Registry support version metadata?** -> Yes, same as dry-cli's registry version support.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask
- **Slice Outcome**: A working `ace-support-cli` gem with Command, Registry, Parser, Runner that passes unit tests and can replace dry-cli's core parsing.
- **Advisory Size**: medium
- **Context Dependencies**: spike results from subtask 0, dry-cli DSL surface, OptionParser stdlib

### Verification Plan

#### Unit / Component Validation
- [ ] Parser coerces all 6 option types correctly.
- [ ] Parser handles required vs optional positional arguments.
- [ ] Parser rejects invalid type values with clear errors.
- [ ] Command DSL stores option/argument/desc/example metadata correctly.
- [ ] Registry resolves single-level and nested commands.
- [ ] Runner dispatches to correct command with parsed params.

#### Integration / E2E Validation
- [ ] End-to-end: define command, register, run with ARGV, verify typed params in `call()`.
- [ ] Multi-command registry with nested subcommands routes correctly.

#### Failure / Invalid-Path Validation
- [ ] Invalid integer/float values produce `ParseError` with flag name.
- [ ] Missing required options produce `ParseError` listing missing flags.
- [ ] Unknown command names produce `CommandNotFoundError`.
- [ ] Unknown flags produce `ParseError` with suggestions.

#### Verification Commands
- [ ] `ace-test ace-support-cli`

## Objective

Build the core ace-support-cli gem providing Command, Registry, Parser, and Runner with automatic type coercion and native array accumulation — the foundation that all downstream gems will depend on.

## Scope of Work

- **User Experience Scope**: Command authors define commands with typed options that just work.
- **System Behavior Scope**: Gem with 6 core classes, OptionParser-based parsing, registry routing.
- **Interface Scope**: `Ace::Support::Cli` namespace with dry-cli-compatible DSL.

### Deliverables

#### Behavioral Specifications
- `ace-support-cli` gem structure (gemspec, lib layout, requires)
- Command, Option, Argument, Parser, Registry, Runner classes
- Unit test suite

#### Validation Artifacts
- Type coercion tests for all 6 types
- Registry routing tests for nested commands
- Error handling tests for invalid inputs

### Consumer Packages

- **ace-support-core**: first consumer (subtask 3)
- **All ~27 downstream gems**: eventual consumers (subtask 4)

## Out of Scope

- ❌ Help formatting (subtask 2)
- ❌ Migration of existing commands (subtasks 3 and 4)
- ❌ StandardOptions, HelpCommand, VersionCommand (subtask 2)

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- Depends on: 8qb.t.q3r.0 (spike validation)
- `ace-support-core/lib/ace/core/cli/dry_cli/base.rb` (DSL to replicate)
