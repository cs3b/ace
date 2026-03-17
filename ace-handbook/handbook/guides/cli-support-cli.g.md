# ace-support-cli CLI Framework Guide

Complete reference for implementing CLI interfaces in ace-* gems using ace-support-cli.

## Overview

All ACE CLI gems use ace-support-cli. See [ADR-023](../../../docs/decisions/ADR-023-ace-support-cli-framework.md) for decision rationale.

**Two patterns:**
- **Multi-command**: Subcommand tools (ace-bundle, ace-taskflow)
- **Single-command**: One-action tools (ace-git-commit, ace-search)

## Multi-Command Pattern

For CLIs with subcommands, use the Registry pattern with `HelpCommand.build()`:

```ruby
# lib/ace/gem/cli.rb
require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/process"
require_relative "cli/commands/status"

module Ace::Gem
  module CLI
    extend Ace::Core::CLI::RegistryDsl

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

    register 'process', Commands::Process
    register 'status', Commands::Status

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
```

**Exe wrapper:**
```ruby
#!/usr/bin/env ruby
require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli::Runner.new(Ace::Gem::CLI).call(args: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

## Single-Command Pattern

For CLIs with one primary action, skip the registry:

```ruby
# lib/ace/gem/cli/commands/search.rb
module Ace::Gem
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
```

**Exe wrapper:**
```ruby
#!/usr/bin/env ruby
require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  Ace::Support::Cli::Runner.new(Ace::Gem::CLI::Commands::Search).call(args: args)
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
end
```

## Command Class Pattern

Commands use `CLI::Commands::` namespace (Hanami pattern):

```ruby
# lib/ace/gem/cli/commands/process.rb
module Ace::Gem
  module CLI
    module Commands
      class Process < Ace::Support::Cli::Command
        include Ace::Core::CLI::Base

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

## Nested Commands

For hierarchical commands (ace-taskflow, ace-git-worktree):

```ruby
# lib/ace/taskflow/cli.rb
module Ace::Taskflow
  module CLI
    extend Ace::Core::CLI::RegistryDsl

    # Hierarchical registration with space-separated names
    register "task show", Commands::Task::Show
    register "task list", Commands::Task::List
    register "release bump", Commands::Release::Bump

    # Help and version
    help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(...)
    register "help", help_cmd
    register "--help", help_cmd
    register "-h", help_cmd
  end
end

# Directory structure:
# lib/ace/taskflow/cli/commands/task/show.rb
# lib/ace/taskflow/cli/commands/task/list.rb
# lib/ace/taskflow/cli/commands/release/bump.rb
```

## Type Conversion

Use the `coerce_types` helper from `Ace::Core::CLI::Base` when you need to coerce values manually:

```ruby
# Single option
opts = coerce_types(options, timeout: :integer)

# Multiple options
opts = coerce_types(options, limit: :integer, ratio: :float)
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

**IMPORTANT**: `Ace::Support::Cli::Runner#call()` returns the command result, but normalizes `nil` to exit code `0`. Use exception-based exit codes for failures:

```ruby
# In command - raise exception for non-zero exit
def call(file: nil, **options)
  raise Ace::Core::CLI::Error.new("file required") if file.nil?

  result = do_work(file)
  raise Ace::Core::CLI::Error.new(result[:error]) unless result[:success]

  puts result[:message]
  # Success - no exception, exits 0
end
```

**Exe wrapper catches exceptions:**
```ruby
#!/usr/bin/env ruby
require "ace/gem"

args = ARGV.empty? ? ["--help"] : ARGV

begin
  exit_code = Ace::Support::Cli::Runner.new(Ace::Gem::CLI).call(args: args)
  exit(exit_code) if exit_code.is_a?(Integer) && exit_code != 0
rescue Ace::Core::CLI::Error => e
  warn e.message
  exit(e.exit_code)
rescue Interrupt
  warn "\nInterrupted"
  exit(130)
end
```

**Exit Code Values:**
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General failure |
| 2 | Invalid arguments |
| 130 | SIGINT (Ctrl+C) |

See [ADR-023](../../../docs/decisions/ADR-023-ace-support-cli-framework.md) for full exit code documentation.

## Reserved Short Flags

| Flag | Meaning | Notes |
|------|---------|-------|
| `-h` | help | ace-support-cli default |
| `-v` | verbose | NOT version |
| `-q` | quiet | Suppress output |
| `-d` | debug | Debug output |
| `-o` | output | Output destination |

## Related

- [ADR-023](../../../docs/decisions/ADR-023-ace-support-cli-framework.md) - Decision record
- [ace-gems.g.md](../../../docs/ace-gems.g.md) - Gem development overview
- Task 179 - Migration details
