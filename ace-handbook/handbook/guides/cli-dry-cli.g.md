# dry-cli CLI Framework Guide

Complete reference for implementing CLI interfaces in ace-* gems using dry-cli.

## Overview

All ACE CLI gems use dry-cli with the Registry pattern. See [ADR-023](../../../docs/decisions/ADR-023-dry-cli-framework.md) for decision rationale.

## Registry Pattern

```ruby
# lib/ace/gem/cli.rb
require "dry/cli"
require "set"
require "ace/core"
require_relative "cli/commands/process"

module Ace::Gem
  module CLI
    extend Dry::CLI::Registry

    # Single source of truth for application commands
    REGISTERED_COMMANDS = %w[process].freeze

    # dry-cli built-ins (standard across all CLI gems)
    BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

    # Auto-derived - no manual maintenance needed
    KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

    DEFAULT_COMMAND = "process"

    # Testable start method with default command routing
    def self.start(args)
      if args.empty? || !KNOWN_COMMANDS.include?(args.first)
        args = [DEFAULT_COMMAND] + args
      end
      Dry::CLI.new(self).call(arguments: args)
    end

    register "process", Commands::Process

    # Version command
    version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
      gem_name: "ace-gem",
      version: Ace::Gem::VERSION
    )
    register "version", version_cmd
    register "--version", version_cmd
  end
end
```

## KNOWN_COMMANDS Pattern

The three-constant pattern ensures adding a new command only requires updating `REGISTERED_COMMANDS`:

```ruby
# Single source of truth for application commands
REGISTERED_COMMANDS = %w[process].freeze

# dry-cli built-ins (standard across all CLI gems)
BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

# Auto-derived using Set for O(1) lookup
KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze
```

**Multi-command example** (ace-review):
```ruby
REGISTERED_COMMANDS = %w[review synthesize list-presets list-prompts].freeze
```

## Command Class Pattern

Commands use `CLI::Commands::` namespace (Hanami pattern):

```ruby
# lib/ace/gem/cli/commands/process.rb
module Ace::Gem
  module CLI
    module Commands
      class Process < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Process file with auto-detection"

        argument :file, required: false, desc: "File to process"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

        def call(file: nil, **options)
          ProcessCommand.new(file, options).execute
        end
      end
    end
  end
end
```

**Directory structure**: `lib/ace/gem/cli/commands/` (not `lib/ace/gem/commands/`)

## Multi-Command CLIs

For tools with subcommands (ace-taskflow):

```ruby
module CLI
  extend Dry::CLI::Registry

  # Hierarchical registration
  register "task show", Commands::TaskShow
  register "task list", Commands::TaskList
  register "tasks", Commands::Tasks  # Alias

  # Nested registration for subcommand groups
  register "worktree create", Commands::WorktreeCreate
  register "worktree delete", Commands::WorktreeDelete
end

# With nested directory structure:
# lib/ace/gem/cli/commands/task/show.rb
module Ace::Gem::CLI::Commands::Task
  class Show < Dry::CLI::Command
    include Ace::Core::CLI::DryCli::Base
    # ...
  end
end
```

## Type Conversion

dry-cli returns strings for all options. Use the `convert_types` helper:

```ruby
# Single option
opts = convert_types(options, timeout: :integer)

# Multiple options
opts = convert_types(options, limit: :integer, ratio: :float)
```

## Help Documentation

Use `desc` with heredoc and `example` array:

```ruby
desc <<~DESC.strip
  Main description here.

  Additional context:
    - Point one
    - Point two
DESC

example ['pattern --flag', '"*.rb" -f']
```

## Exit Code Handling

Commands return status codes, never call `exit`:

```ruby
# In command
def execute
  return 1 if invalid?
  0  # Success
end

# exe/ace-gem handles exit
exit_code = Ace::Gem::CLI.start(ARGV)
exit(exit_code || 0)
```

## Reserved Short Flags

| Flag | Meaning | Notes |
|------|---------|-------|
| `-h` | help | dry-cli default |
| `-v` | verbose | NOT version |
| `-q` | quiet | Suppress output |
| `-d` | debug | Debug output |
| `-o` | output | Output destination |

## Related

- [ADR-023](../../../docs/decisions/ADR-023-dry-cli-framework.md) - Decision record
- [ace-gems.g.md](../../../docs/ace-gems.g.md) - Gem development overview
- Task 179 - Migration details
