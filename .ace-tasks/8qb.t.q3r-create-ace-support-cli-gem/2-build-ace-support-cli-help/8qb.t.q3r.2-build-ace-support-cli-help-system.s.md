---
id: 8qb.t.q3r.2
status: done
priority: medium
created_at: "2026-03-12 17:25:43"
estimate: Medium
dependencies: [8qb.t.q3r.1]
tags: [cli, help, formatting]
parent: 8qb.t.q3r
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb, ace-support-core/lib/ace/core/cli/dry_cli/help_command.rb, ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb, ace-support-core/lib/ace/core/cli/dry_cli/base.rb]
  commands: []
needs_review: false
---

# Build ace-support-cli help system

## Behavioral Specification

### User Experience
- **Input**: Users invoke `--help` or `-h` on any command or at registry level.
- **Process**: The help system renders formatted output natively within ace-support-cli, replacing the current monkey-patches on `Dry::CLI::Banner` and `Dry::CLI::Usage`. Two-tier help distinguishes `-h` (concise) from `--help` (full).
- **Output**: Help output identical to current monkey-patched format — ALL-CAPS section headers, consistent alignment, grouped subcommands.

### Expected Behavior

The help system ports these currently monkey-patched components into native implementations:
1. **Banner** (full `--help`): Renders NAME, USAGE, DESCRIPTION, SUBCOMMANDS, ARGUMENTS, OPTIONS, EXAMPLES sections with ALL-CAPS headers. Replaces the monkey-patch on `Dry::CLI::Banner`.
2. **Usage** (registry-level help): Renders the command listing when no specific command is given. Supports `COMMAND_GROUPS` for grouped display. Replaces the monkey-patch on `Dry::CLI::Usage`.
3. **HelpConcise** (`-h`): Compact help showing header, usage, options block (no full descriptions), and up to 3 examples. Port of current `help_concise.rb`.
4. **HelpCommand.build()**: Factory for creating top-level help commands in registries. Port of current `help_command.rb`.
5. **VersionCommand.build()**: Factory for creating standard `--version` commands. Port of current `version_command.rb`. Note: `-v` is reserved for `--verbose`.
6. **CommandGroups**: Support for grouping subcommands in registry-level help display.
7. **StandardOptions**: Integration of standard options (`--quiet`, `--verbose`, `--debug`) into help output.
8. **Two-tier help**: `-h` triggers concise help, `--help` triggers full help. Detected via `AceTwoTierHelp` equivalent.

### Interface Contract

```ruby
# Banner (full --help for a single command)
banner = Ace::Support::Cli::Banner.new(command_class)
banner.render  # => formatted string with ALL-CAPS sections

# Usage (registry-level listing)
usage = Ace::Support::Cli::Usage.new(registry, program_name: "ace-tool")
usage.render          # => full registry help
usage.render_concise  # => compact -h registry help

# HelpCommand factory
help_cmd = Ace::Support::Cli::HelpCommand.build(
  program_name: "ace-tool",
  version: "1.0.0",
  commands: registry.commands,
  examples: ["ace-tool lint .", "ace-tool test atoms"]
)

# VersionCommand factory
version_cmd = Ace::Support::Cli::VersionCommand.build(
  gem_name: "ace-tool",
  version: "1.0.0"
)
```

```text
# Expected --help output format (must match current)
NAME
  ace-tool lint - Run linter on files

USAGE
  ace-tool lint [OPTIONS] [PATH]

DESCRIPTION
  Runs the linter on the specified path with configurable rules.

ARGUMENTS
  PATH                    # Path to lint (default: .)

OPTIONS
  --timeout=VALUE, -t     # Timeout in seconds (default: 30)
  --format=VALUE          # Output format: json, text (default: json)
  --verbose, --no-verbose # Enable verbose output
  --help, -h              # Show this help

EXAMPLES
  ace-tool lint .
  ace-tool lint src/ --format text --timeout 60
```

```text
# Expected -h output format (concise, must match current)
ace-tool lint - Run linter on files

Usage: ace-tool lint [OPTIONS] [PATH]

Options: --timeout, --format, --verbose, --help

Examples:
  ace-tool lint .
  ace-tool lint src/ --format text
```

**Error Handling:**
- Missing command descriptions degrade gracefully (omit DESCRIPTION section rather than erroring).
- Commands with no options omit the OPTIONS section.
- Commands with no examples omit the EXAMPLES section.

**Edge Cases:**
- Commands with only boolean options show `--[no-]flag` form.
- Options with `values:` constraint show allowed values in help text.
- Required options are marked in help output.
- Aliased options show both long and short forms.
- Very long option names wrap or truncate at terminal width.

### Success Criteria

- [ ] **Output identical**: `--help` output matches current monkey-patched format character-for-character.
- [x] **Two-tier help works**: `-h` shows concise, `--help` shows full.
- [x] **HelpCommand factory works**: builds top-level help for registries.
- [x] **VersionCommand factory works**: builds `--version` commands with correct format.
- [x] **CommandGroups work**: grouped subcommand display in registry help.
- [x] **No monkey-patches**: all formatting is native to ace-support-cli.

### Validation Questions

- [x] **Must output be character-identical?** -> Yes, to avoid breaking visual expectations and documentation screenshots.
- [x] **Should -h and --help remain two-tier?** -> Yes, this is a valued UX pattern.
- [x] **Is `-v` for version?** -> No, `-v` is reserved for `--verbose`. Version is only via `--version`.

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Subtask
- **Slice Outcome**: Complete help system within ace-support-cli that produces identical output to current monkey-patched dry-cli help, with no monkey-patches.
- **Advisory Size**: medium
- **Context Dependencies**: subtask 1 (gem core), current help_formatter.rb, usage_formatter.rb, help_concise.rb, help_command.rb, version_command.rb

### Verification Plan

#### Unit / Component Validation
- [x] Banner renders ALL-CAPS sections with correct content for representative commands.
- [x] Usage renders grouped command listings for representative registries.
- [x] HelpConcise renders compact output with option names only.
- [x] HelpCommand.build() produces working help commands.
- [x] VersionCommand.build() produces working version commands.

#### Integration / E2E Validation
- [ ] `ace-tool --help` output matches current output (diff comparison).
- [ ] `ace-tool -h` output matches current output (diff comparison).
- [ ] `ace-tool lint --help` output matches current output (diff comparison).

#### Failure / Invalid-Path Validation
- [x] Commands with no desc/options/examples degrade gracefully.
- [ ] Empty registries produce useful help output.

#### Verification Commands
- [x] `ace-test ace-support-cli`
- [ ] Diff comparison of help output before/after migration (manual during subtask 3)

## Objective

Port dry-cli's monkey-patched help formatting into native ace-support-cli implementations that produce identical output, enabling clean removal of the monkey-patches.

## Scope of Work

- **User Experience Scope**: Help output looks exactly the same to users.
- **System Behavior Scope**: Banner, Usage, HelpConcise, HelpCommand, VersionCommand, CommandGroups, two-tier help.
- **Interface Scope**: `Ace::Support::Cli` namespace classes with `render` methods.

### Deliverables

#### Behavioral Specifications
- Banner, Usage, HelpConcise classes
- HelpCommand.build(), VersionCommand.build() factories
- Two-tier help detection and routing
- CommandGroups support

#### Validation Artifacts
- Output comparison tests against current monkey-patched format
- Unit tests for each help component

### Consumer Packages

- **ace-support-core**: uses help system through Base module (subtask 3)
- **All CLI gems**: inherit help system through command base class

## Out of Scope

- ❌ Changing help output format or adding new sections
- ❌ Terminal width detection or dynamic wrapping (match current behavior)
- ❌ Color/ANSI formatting (match current plain-text output)

## References

- Parent: 8qb.t.q3r — Create ace-support-cli gem to replace dry-cli
- Depends on: 8qb.t.q3r.1 (gem core)
- `ace-support-core/lib/ace/core/cli/dry_cli/help_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/usage_formatter.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_concise.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/help_command.rb`
- `ace-support-core/lib/ace/core/cli/dry_cli/version_command.rb`
