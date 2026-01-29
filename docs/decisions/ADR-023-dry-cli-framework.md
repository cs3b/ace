# ADR-023: dry-cli CLI Framework

## Status

**Implemented** - January 29, 2026
Accepted: January 7, 2026

Supersedes: ADR-018 (Thor CLI Commands Pattern)

### Implementation Notes

- All 25+ ace-* CLI gems migrated to dry-cli with exception-based exit code pattern
- `Ace::Core::CLI::Error` in ace-support-core v0.22.0+
- Task 229 completed migration
- Error messages automatically prefixed with "Error: " via `Error#to_s`
- Domain errors (e.g., ace-coworker) can inherit from `Ace::Core::CLI::Error` for direct exit code support

## Context

ADR-018 established Thor as the standard CLI framework for ace-* gems in October 2025. While Thor provided consistency across the growing gem ecosystem, production use revealed fundamental design limitations that could not be worked around:

### Thor Limitations Discovered in Production

1. **Option consumption conflicts** - Thor consumes declared options before calling the method
   - Example: `ace-git-worktree create --task 178` would fail because Thor consumed `--task`
   - Workaround (`stop_on_unknown_option!`) was fragile and incomplete

2. **Nested subcommand limitations** - Thor issue #489 open since 2014
   - Affects complex CLIs with multiple subcommand levels
   - No upstream fix forthcoming

3. **Default command workarounds** - Manual handling needed for default task routing
   - Thor's `default_task` requires custom `method_missing` implementations
   - Inconsistent behavior across gems

4. **Help flag boilerplate** - Every command needed `if args.first == "--help"` checks
   - Repetitive code across 13+ gems
   - Easy to forget, leading to inconsistent help behavior

### Evidence from Production

The ace-git-worktree gem documented concrete bugs in its CHANGELOG:

- **v0.10.2** (Jan 6, 2026): Fixed Thor consuming `--files` option in config command
- **v0.10.1** (Jan 6, 2026): Fixed Thor consuming `--task`, `--pr`, `--branch` options

These bugs directly impacted users - commands appeared to ignore their arguments.

## Decision

All ace-* gems with CLI interfaces **must** use dry-cli with standardized `cli/` directory structure:

```
lib/ace/gem/
├── cli/                    # dry-cli command classes
│   ├── shared_helpers.rb   # Common helpers (display_config_summary, options_to_args)
│   ├── process.rb          # ProcessCommand class
│   └── status.rb           # StatusCommand class
├── commands/               # Business logic (unchanged from ADR-018)
│   ├── process_command.rb
│   └── status_command.rb
├── cli.rb                  # dry-cli Registry entry point
└── version.rb
```

### CLI Entry Point (`cli.rb`)

```ruby
# lib/ace/gem/cli.rb
require "dry/cli"
require "set"

module Ace
  module Gem
    module CLI
      extend Dry::CLI::Registry

      # Commands in this CLI
      REGISTERED_COMMANDS = %w[process status].freeze
      COMMAND_ALIASES = %w[ps].freeze  # If any
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + COMMAND_ALIASES + BUILTIN_COMMANDS).freeze
      DEFAULT_COMMAND = "process"

      # Testable start method with default command routing
      # Note: Returns nil (dry-cli behavior). Exit codes via exceptions.
      def self.start(args)
        if args.empty? || !KNOWN_COMMANDS.include?(args.first)
          args = [DEFAULT_COMMAND] + args
        end
        Dry::CLI.new(self).call(arguments: args)
      end

      register "process", Process, aliases: ["ps"]
      register "status", Status, aliases: []

      # Version command using ace-support-core helper
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-gem",
        version: Ace::Gem::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
```

### Command Class Pattern (`cli/process.rb`)

```ruby
# lib/ace/gem/cli/process.rb
require "dry/cli"
require_relative "shared_helpers"
require_relative "../commands/process_command"

module Ace
  module Gem
    module CLI
      class Process < Dry::CLI::Command
        include SharedHelpers

        desc "Process a file"

        example [
          "file.txt              # Process single file",
          "--verbose file.txt    # Process with verbose output"
        ]

        argument :file, required: true, desc: "File to process"

        option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
        option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

        def call(file:, **options)
          display_config_summary("process", options)

          args = options_to_args(options)
          args << file

          Commands::ProcessCommand.new.run(args)
        end
      end
    end
  end
end
```

### Shared Helpers (`cli/shared_helpers.rb`)

```ruby
# lib/ace/gem/cli/shared_helpers.rb
require "ace/core"

module Ace
  module Gem
    module CLI
      module SharedHelpers
        include Ace::Core::CLI::DryCli::Base

        private

        def display_config_summary(command, options)
          return if quiet?(options)

          Ace::Core::Atoms::ConfigSummary.display(
            command: command,
            config: Ace::Gem.config,
            defaults: {},
            options: options,
            quiet: quiet?(options)
          )
        end

        def options_to_args(options)
          args = []
          options.each do |key, value|
            next if value.nil? || key == :quiet

            arg_key = key.to_s.tr("_", "-")
            if value == true
              args << "--#{arg_key}"
            elsif value == false
              next
            elsif value.is_a?(String)
              args << "--#{arg_key}"
              args << value
            end
          end
          args
        end
      end
    end
  end
end
```

### Exit Code Handling

#### Understanding dry-cli's Behavior

**Critical fact**: `Dry::CLI.new(registry).call(arguments: args)` returns `nil`, **NOT** the command's return value. This is by design - dry-cli maintainers consider exit codes and return values to be separate concerns ([GitHub Issue #47](https://github.com/dry-rb/dry-cli/issues/47)).

The dry-cli maintainers' official recommendation is to call `exit()` directly in commands. However, this breaks testability. Hanami (dry-cli's creator) uses an exception-based pattern instead.

#### ACE Pattern: Exception-Based Exit Codes (Recommended)

ACE gems use an exception-based pattern for exit codes, similar to [Hanami CLI](https://github.com/hanami/cli):

**1. Define CLI error class (in ace-support-core):**
```ruby
# lib/ace/core/cli/error.rb
module Ace
  module Core
    module CLI
      # Raise to signal non-zero exit code
      class Error < StandardError
        attr_reader :exit_code

        def initialize(message, exit_code: 1)
          super(message)
          @exit_code = exit_code
        end
      end
    end
  end
end
```

**2. Command raises error on failure:**
```ruby
# lib/ace/gem/cli/commands/process.rb
def call(file:, **options)
  raise Ace::Core::CLI::Error.new("file required") if file.nil?

  result = do_work(file)

  if result[:success]
    puts result[:message]
    # Success - no exception, exits 0
  else
    raise Ace::Core::CLI::Error.new(result[:error])
  end
end
```

**3. Exe wrapper catches and exits:**
```ruby
# exe/ace-gem
#!/usr/bin/env ruby
require "ace/gem"

begin
  Ace::Gem::CLI.start(ARGV)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

#### Testing Commands

The exception pattern enables clean testing:

```ruby
def test_missing_file_raises_error
  error = assert_raises(Ace::Core::CLI::Error) do
    capture_io { CLI.start(["process"]) }
  end
  assert_equal "file required", error.message
  assert_equal 1, error.exit_code
end

def test_successful_processing
  # No exception = success (exit 0)
  output, = capture_io { CLI.start(["process", "test.txt"]) }
  assert_includes output, "Processed"
end
```

#### Exit Code Values

| Code | Meaning | How to Signal |
|------|---------|---------------|
| 0 | Success | Return normally (no exception) |
| 1 | General failure | `raise Ace::Core::CLI::Error.new(msg)` |
| 2 | Misuse/invalid args | `raise Ace::Core::CLI::Error.new(msg, exit_code: 2)` |
| 3 | Configuration error | `raise Ace::Core::CLI::Error.new(msg, exit_code: 3)` |
| 4 | Resource not found | `raise Ace::Core::CLI::Error.new(msg, exit_code: 4)` |
| 130 | SIGINT (Ctrl+C) | Caught by exe wrapper (see below) |

#### SIGINT Handling

CLI tools should handle SIGINT (Ctrl+C) gracefully and return exit code 130 (128 + signal 2):

```ruby
# exe/ace-gem
#!/usr/bin/env ruby
require "ace/gem"

begin
  Ace::Gem::CLI.start(ARGV)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
rescue Interrupt
  # SIGINT (Ctrl+C) - convention: 128 + signal number (2)
  warn "\nInterrupted"
  exit(130)
end
```

#### Exit Code Contract Documentation

When implementing CLI commands, document exit codes in the command's help text or `docs/usage.md`:

```markdown
## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 130 | Interrupted (Ctrl+C) |
```

**Task specification requirement**: For CLI tasks, include exit code semantics in the Interface Contract section of the behavioral specification.

#### Anti-Patterns (DO NOT USE)

**❌ Returning integers from commands:**
```ruby
# WRONG - dry-cli ignores return values
def call(**)
  return 1 if error?  # This does NOTHING
  0                    # Also ignored
end
```

**❌ Thread-local storage:**
```ruby
# WRONG - unnecessary complexity
Thread.current[:exit_code] = 1  # Don't do this
```

**❌ Direct exit() calls (breaks tests):**
```ruby
# WRONG - untestable
def call(**)
  exit(1) if error?  # Terminates test process
end
```

#### Migration Path

Existing commands that return integers need updating:

```ruby
# Before (broken - always exits 0)
def call(**options)
  return 1 if invalid?
  do_work
  0
end

# After (correct - uses exceptions)
def call(**options)
  raise Ace::Core::CLI::Error.new("validation failed") if invalid?
  do_work
  # Success - exits 0
end
```

### Requirements

**DO:**
- Use dry-cli Registry pattern in `cli.rb`
- Create `cli/` directory for command classes
- Include SharedHelpers in command classes
- Include command aliases in `KNOWN_COMMANDS`
- Use `self.start(args)` for testable entry point
- Test in `test/commands/` (unchanged from ADR-018)
- Reserve `-v` for `--verbose` (inherited from ADR-018)
- Raise `Ace::Core::CLI::Error` for non-zero exit codes
- Catch `Ace::Core::CLI::Error` in exe wrappers and call `exit(e.exit_code)`

**DON'T:**
- Use Thor (deprecated)
- Put all options in cli.rb (let commands define their own)
- Return integers from commands expecting them to become exit codes (dry-cli ignores returns)
- Use `exit()` directly in command classes (breaks testability)
- Use thread-local storage for exit codes (unnecessary complexity)
- Duplicate helpers across command files (use SharedHelpers)

## Consequences

### Positive

- **No option consumption bugs**: Commands receive all options as intended
- **Simpler default routing**: `KNOWN_COMMANDS` set provides clean routing
- **Better testability**: `CLI.start(args)` can be called directly in tests
- **Less boilerplate**: Automatic help generation, no manual `--help` checks
- **Consistent patterns**: SharedHelpers DRY up common code

### Negative

- **Migration effort**: 13+ gems needed CLI rewrites
- **Learning curve**: Developers must learn dry-cli patterns
- **String option values**: dry-cli returns all option values as strings (requires explicit type conversion)
- **Exit code pattern**: dry-cli doesn't propagate return values as exit codes; requires exception-based pattern for testable exit code handling

### Neutral

- **Two-layer structure**: `cli/` (dry-cli) + `commands/` (business logic)
- **Separate files**: Each command is its own file in `cli/`

## Migration from Thor (ADR-018)

Key differences when migrating:

| Aspect | Thor (ADR-018) | dry-cli (ADR-023) |
|--------|----------------|-------------------|
| Entry point | `class CLI < Thor` | `module CLI; extend Dry::CLI::Registry` |
| Commands | Methods on CLI class | Separate classes in `cli/` |
| Options | `class_option` on CLI | `option` on each command |
| Default command | `default_task :name` | `KNOWN_COMMANDS` + routing |
| Version | `version_command` helper | `VersionCommand.build` |
| Help | Automatic but inconsistent | Automatic and consistent |
| Aliases | `aliases: ["alias"]` in register | Same |

## Exe Wrapper Pattern

```ruby
# exe/ace-gem
#!/usr/bin/env ruby
# frozen_string_literal: true

require "ace/gem"

begin
  Ace::Gem::CLI.start(ARGV)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

## Testing Pattern

```ruby
# test/commands/cli_test.rb
class CliTest < AceTestCase
  def test_process_command_success
    output, = capture_io do
      Ace::Gem::CLI.start(["process", "file.txt"])
    end
    assert_includes output, "Processed"
    # No exception = exit code 0
  end

  def test_process_command_failure
    error = assert_raises(Ace::Core::CLI::Error) do
      capture_io { Ace::Gem::CLI.start(["process"]) }
    end
    assert_equal 1, error.exit_code
    assert_includes error.message, "file required"
  end

  def test_default_command_routing
    output, = capture_io do
      Ace::Gem::CLI.start(["file.txt"])  # No command specified
    end
    assert_includes output, "Processed"
  end

  def test_alias_routing
    # Aliases must be in KNOWN_COMMANDS to work
    assert Ace::Gem::CLI::KNOWN_COMMANDS.include?("ps")
  end
end
```

## Examples from Production

### ace-git-worktree (Complex CLI)
```
lib/ace/git/worktree/
├── cli/
│   ├── shared_helpers.rb   # Common methods
│   ├── create.rb
│   ├── list.rb
│   ├── switch.rb
│   ├── remove.rb
│   ├── prune.rb
│   └── config.rb
├── commands/               # Business logic unchanged
│   ├── create_command.rb
│   └── [... 5 more]
├── cli.rb                  # Registry with KNOWN_COMMANDS
└── version.rb
```

### ace-search (Simple CLI)
```
lib/ace/search/
├── cli/
│   └── search.rb
├── commands/
│   └── search_command.rb
├── cli.rb
└── version.rb
```

## Related Decisions

- **ADR-018** (archived): Original Thor decision this supersedes
- **ADR-011**: ATOM Architecture - commands coordinate ATOM components
- **ADR-017**: Flat Test Structure - test/commands/ for command tests
- **ADR-022**: Configuration Architecture - commands use config cascade

## References

- **dry-cli docs**: https://dry-rb.org/gems/dry-cli/1.1/
- **dry-cli exit code issue**: https://github.com/dry-rb/dry-cli/issues/47 (explains why returns aren't exit codes)
- **dry-cli exit code PR**: https://github.com/dry-rb/dry-cli/pull/48 (maintainers' position on exit codes)
- **Hanami CLI exe**: https://github.com/hanami/cli/blob/main/exe/hanami (exception-based pattern)
- **Thor issue #489**: https://github.com/rails/thor/issues/489 (nested subcommands)
- **Task 179**: Migration orchestrator with full rationale
- **ace-support-core**: Base infrastructure for dry-cli

---

This ADR establishes dry-cli as the standard CLI framework for all ACE gems, replacing Thor (ADR-018) due to fundamental design limitations discovered in production.

**January 2026 Update**: Added exception-based exit code pattern after discovering that dry-cli's `call()` method returns `nil`, not command return values. The pattern follows Hanami's approach for testable exit code handling.
