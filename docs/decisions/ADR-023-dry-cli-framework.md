# ADR-023: ace-support-cli CLI Framework

## Status

**Implemented** - January 29, 2026
Accepted: January 7, 2026

Supersedes: ADR-018 (Thor CLI Commands Pattern)

### Implementation Notes

- All 25+ ace-* CLI gems migrated to ace-support-cli with exception-based exit code pattern
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

All ace-* gems with CLI interfaces **must** use ace-support-cli with standardized `cli/` directory structure:

```
lib/ace/gem/
├── cli/                    # ace-support-cli command classes
│   ├── shared_helpers.rb   # Common helpers (display_config_summary, options_to_args)
│   ├── process.rb          # ProcessCommand class
│   └── status.rb           # StatusCommand class
├── commands/               # Business logic (unchanged from ADR-018)
│   ├── process_command.rb
│   └── status_command.rb
├── cli.rb                  # ace-support-cli Registry entry point
└── version.rb
```

### Two CLI Patterns

ACE gems use two patterns depending on complexity:

#### Multi-Command Pattern (subcommand tools)

For CLIs with multiple commands (ace-bundle, ace-taskflow, ace-git-worktree):

```ruby
# lib/ace/gem/cli.rb
require "dry/cli"
require "ace/core"
require_relative "cli/commands/process"
require_relative "cli/commands/status"

module Ace
  module Gem
    module CLI
      extend Ace::Support::Cli::Registry

      PROGRAM_NAME = 'ace-gem'

      # Commands with descriptions for help output
      REGISTERED_COMMANDS = [
        ['process', 'Process files with auto-detection'],
        ['status',  'Show current status']
      ].freeze

      HELP_EXAMPLES = [
        'ace-gem process file.txt',
        'ace-gem status --verbose'
      ].freeze

      register 'process', Commands::Process.new
      register 'status', Commands::Status.new

      # Version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: 'ace-gem',
        version: Ace::Gem::VERSION
      )
      register 'version', version_cmd
      register '--version', version_cmd

      # Help command (standard pattern)
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Gem::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register 'help', help_cmd
      register '--help', help_cmd
      register '-h', help_cmd
    end
  end
end
```

**Exe wrapper** (handles no-args case):
```ruby
#!/usr/bin/env ruby
require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

#### Single-Command Pattern

For CLIs with one primary action (ace-git-commit, ace-search, ace-test):

```ruby
# lib/ace/gem/cli/commands/search.rb (no separate cli.rb registry)
module Ace
  module Search
    module CLI
      module Commands
        class Search < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc "Search files and content"
          argument :pattern, required: false
          option :files, type: :boolean, aliases: ["-f"]

          def call(pattern: nil, **options)
            # ... implementation
          end
        end
      end
    end
  end
end
```

**Exe wrapper**:
```ruby
#!/usr/bin/env ruby
require "ace/search"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Search::CLI::Commands::Search).call(arguments: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
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
      class Process < Ace::Support::Cli::Command
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
        include Ace::Core::CLI::Base

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

#### Understanding ace-support-cli's Behavior

**Critical fact**: `Ace::Support::Cli.new(registry).call(arguments: args)` returns `nil`, **NOT** the command's return value. This is by design - ace-support-cli maintainers consider exit codes and return values to be separate concerns ([GitHub Issue #47](https://github.com/dry-rb/ace-support-cli/issues/47)).

The ace-support-cli maintainers' official recommendation is to call `exit()` directly in commands. However, this breaks testability. Hanami (ace-support-cli's creator) uses an exception-based pattern instead.

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

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: args)
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
    capture_io { Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: ["process"]) }
  end
  assert_equal "file required", error.message
  assert_equal 1, error.exit_code
end

def test_successful_processing
  # No exception = success (exit 0)
  output, = capture_io do
    Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: ["process", "test.txt"])
  end
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

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: args)
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
# WRONG - ace-support-cli ignores return values
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
- Use ace-support-cli Registry pattern in `cli.rb` (multi-command) or direct command class (single-command)
- Create `cli/commands/` directory for command classes
- Include `Ace::Core::CLI::Base` in command classes
- Use `HelpCommand.build()` for multi-command CLIs
- Use `VersionCommand.build()` for version commands
- Test in `test/commands/`
- Reserve `-v` for `--verbose` (inherited from ADR-018)
- Raise `Ace::Core::CLI::Error` for non-zero exit codes
- Catch `Ace::Core::CLI::Error` in exe wrappers and call `exit(e.exit_code)`
- Handle no-args with `ARGV.empty? ? ["--help"] : ARGV`

**DON'T:**
- Use Thor (deprecated)
- Use DWIM default routing (removed in Task 278)
- Put all options in cli.rb (let commands define their own)
- Return integers from commands expecting them to become exit codes (ace-support-cli ignores returns)
- Use `exit()` directly in command classes (breaks testability)
- Use thread-local storage for exit codes (unnecessary complexity)
- Create `KNOWN_COMMANDS`, `DEFAULT_COMMAND`, `BUILTIN_COMMANDS` constants (removed)

## Consequences

### Positive

- **No option consumption bugs**: Commands receive all options as intended
- **Standard help behavior**: No-args shows help (aligns with clig.dev conventions)
- **Better testability**: `Ace::Support::Cli.new().call()` can be tested directly
- **Less boilerplate**: Automatic help generation via `HelpCommand.build()`
- **Consistent patterns**: Two patterns (multi-command vs single-command) cover all cases

### Negative

- **Migration effort**: 13+ gems needed CLI rewrites
- **Learning curve**: Developers must learn ace-support-cli patterns
- **String option values**: ace-support-cli returns all option values as strings (requires explicit type conversion)
- **Exit code pattern**: ace-support-cli doesn't propagate return values as exit codes; requires exception-based pattern for testable exit code handling

### Neutral

- **Two-layer structure**: `cli/` (ace-support-cli) + `commands/` (business logic)
- **Separate files**: Each command is its own file in `cli/`

## Migration from Thor (ADR-018)

Key differences when migrating:

| Aspect | Thor (ADR-018) | ace-support-cli (ADR-023) |
|--------|----------------|-------------------|
| Entry point | `class CLI < Thor` | `module CLI; extend Ace::Support::Cli::Registry` |
| Commands | Methods on CLI class | Separate classes in `cli/commands/` |
| Options | `class_option` on CLI | `option` on each command |
| No-args behavior | `default_task :name` | Shows help (`["--help"]`) |
| Version | `version_command` helper | `VersionCommand.build()` |
| Help | Automatic but inconsistent | `HelpCommand.build()` for multi-command |
| Aliases | `aliases: ["alias"]` in register | Same |

## Exe Wrapper Pattern

**Multi-command CLI:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

**Single-command CLI:**
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli.new(Ace::Gem::CLI::Commands::Process).call(arguments: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

## Testing Pattern

For multi-command CLIs, test via `Ace::Support::Cli.new(Registry).call()`:

```ruby
# test/commands/cli_test.rb
class CliTest < AceTestCase
  def test_process_command_success
    output, = capture_io do
      Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: ["process", "file.txt"])
    end
    assert_includes output, "Processed"
    # No exception = exit code 0
  end

  def test_process_command_failure
    error = assert_raises(Ace::Core::CLI::Error) do
      capture_io { Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: ["process"]) }
    end
    assert_equal 1, error.exit_code
    assert_includes error.message, "file required"
  end

  def test_no_args_shows_help
    output, = capture_io do
      Ace::Support::Cli.new(Ace::Gem::CLI).call(arguments: ["--help"])
    end
    assert_includes output, "Commands:"
    assert_includes output, "process"
  end
end
```

For single-command CLIs:

```ruby
class SingleCommandCliTest < AceTestCase
  def test_search_success
    output, = capture_io do
      Ace::Support::Cli.new(Ace::Search::CLI::Commands::Search).call(arguments: ["pattern"])
    end
    assert_includes output, "Results"
  end
end
```

## Examples from Production

### ace-bundle (Multi-Command CLI)
```
ace-bundle/
├── lib/ace/bundle/
│   ├── cli/
│   │   └── commands/
│   │       ├── load.rb
│   │       └── list.rb
│   ├── cli.rb                  # Registry with HelpCommand.build()
│   └── version.rb
├── exe/ace-bundle              # Ace::Support::Cli.new(CLI).call()
└── ...
```

### ace-git-commit (Single-Command CLI)
```
ace-git-commit/
├── lib/ace/git_commit/
│   ├── cli/
│   │   └── commit.rb           # Single command class
│   └── version.rb
├── exe/ace-git-commit          # Ace::Support::Cli.new(Commands::Commit).call()
└── ...
```

### ace-git-worktree (Multi-Command CLI with Aliases)
```
ace-git-worktree/
├── lib/ace/git/worktree/
│   ├── cli/
│   │   └── commands/
│   │       ├── create.rb
│   │       ├── list.rb
│   │       ├── switch.rb
│   │       ├── remove.rb
│   │       └── prune.rb
│   ├── cli.rb                  # Registry with commands
│   └── version.rb
├── exe/ace-git-worktree
└── ...
```

## Related Decisions

- **ADR-018** (archived): Original Thor decision this supersedes
- **ADR-011**: ATOM Architecture - commands coordinate ATOM components
- **ADR-017**: Flat Test Structure - test/commands/ for command tests
- **ADR-022**: Configuration Architecture - commands use config cascade

## References

- **ace-support-cli docs**: https://dry-rb.org/gems/ace-support-cli/1.1/
- **ace-support-cli exit code issue**: https://github.com/dry-rb/ace-support-cli/issues/47 (explains why returns aren't exit codes)
- **ace-support-cli exit code PR**: https://github.com/dry-rb/ace-support-cli/pull/48 (maintainers' position on exit codes)
- **Hanami CLI exe**: https://github.com/hanami/cli/blob/main/exe/hanami (exception-based pattern)
- **Thor issue #489**: https://github.com/rails/thor/issues/489 (nested subcommands)
- **Task 179**: Migration orchestrator with full rationale
- **ace-support-core**: Base infrastructure for ace-support-cli

---

This ADR establishes ace-support-cli as the standard CLI framework for all ACE gems, replacing Thor (ADR-018) due to fundamental design limitations discovered in production.

**January 2026 Update**: Added exception-based exit code pattern after discovering that ace-support-cli's `call()` method returns `nil`, not command return values. The pattern follows Hanami's approach for testable exit code handling.
