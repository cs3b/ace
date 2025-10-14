# ADR-018: Thor CLI Commands Pattern

## Status
Accepted
Date: October 14, 2025

## Context

As ACE gems grew from 4 to 15+, different CLI implementation patterns emerged. Some used Thor, others used OptionParser, and organization varied. This inconsistency made gems harder to maintain and understand.

### Requirements

1. **Consistent CLI**: All gems should have similar command structure
2. **Testability**: Commands must be easily testable in isolation
3. **Extensibility**: Easy to add new commands
4. **User Experience**: Consistent help, options, error handling
5. **Maintainability**: Clear separation of concerns

### Observed Best Practice

Production gems (ace-lint, ace-docs, ace-taskflow) converged on Thor with commands/ directory:
- Thor provides consistent CLI framework
- commands/ directory separates command logic
- Each command is independently testable
- Help and error handling standardized

## Decision

All ace-* gems with CLI interfaces **must** use Thor with standardized commands/ directory structure:

```
lib/ace/gem/
├── commands/              # Command classes
│   ├── base_command.rb   # Shared command logic (optional)
│   ├── process_command.rb
│   └── status_command.rb
├── cli.rb                # Thor CLI entry point
└── version.rb
```

### CLI Entry Point (`cli.rb`)

```ruby
# lib/ace/gem/cli.rb
require 'thor'

module Ace
  module Gem
    class CLI < Thor
      desc "process FILE", "Process a file"
      option :verbose, type: :boolean, aliases: '-v'
      option :debug, type: :boolean, aliases: '-d'
      def process(file)
        require_relative 'commands/process_command'
        Commands::ProcessCommand.new(file, options).execute
      end

      desc "status", "Show status"
      def status
        require_relative 'commands/status_command'
        Commands::StatusCommand.new(options).execute
      end

      desc "version", "Show version"
      def version
        puts Ace::Gem::VERSION
      end
    end
  end
end
```

### Command Class Pattern

```ruby
# lib/ace/gem/commands/process_command.rb
module Ace
  module Gem
    module Commands
      class ProcessCommand
        def initialize(file, options = {})
          @file = file
          @options = options
          @config = Gem.config  # Use gem config cascade
        end

        def execute
          # Command logic using organisms/molecules
          # Return exit code (0 = success, 1 = error)
          0
        rescue => e
          warn "Error: #{e.message}"
          1
        end
      end
    end
  end
end
```

### Executable (`exe/ace-gem`)

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/ace/gem'

begin
  Ace::Gem::CLI.start(ARGV)
rescue => e
  warn "Error: #{e.message}"
  exit 1
end
```

### Requirements

**DO:**
- ✅ Use Thor for CLI framework
- ✅ Create commands/ directory for command classes
- ✅ Each command in separate file
- ✅ cli.rb as single entry point
- ✅ Commands return exit codes (0/1)
- ✅ Use gem config cascade in commands
- ✅ Provide --help for all commands
- ✅ Handle errors gracefully

**DON'T:**
- ❌ Use OptionParser directly
- ❌ Put command logic in cli.rb
- ❌ Use `exit()` in command classes
- ❌ Hardcode configuration values
- ❌ Mix command logic with business logic

## Consequences

### Positive

- **Consistency**: All gems use same CLI pattern
- **Testability**: Commands easily tested in isolation
- **Maintainability**: Clear separation of concerns
- **User Experience**: Consistent help, options, error messages
- **Extensibility**: Easy to add new commands
- **Documentation**: Thor generates help automatically

### Negative

- **Thor Dependency**: All gems depend on Thor
- **Learning Curve**: Developers must learn Thor
- **Migration Effort**: Existing OptionParser code needs conversion

### Neutral

- **Command Overhead**: Each command is separate file
- **Exit Codes**: Must return instead of calling exit()

## Testing Pattern

```ruby
# test/commands/process_command_test.rb
class ProcessCommandTest < AceTestCase
  def test_execute_success
    command = Ace::Gem::Commands::ProcessCommand.new('file.txt', {})
    assert_equal 0, command.execute
  end

  def test_execute_with_verbose
    command = Ace::Gem::Commands::ProcessCommand.new('file.txt', verbose: true)
    assert_equal 0, command.execute
  end

  def test_execute_handles_errors
    command = Ace::Gem::Commands::ProcessCommand.new('missing.txt', {})
    assert_equal 1, command.execute
  end
end
```

## Integration with ATOM

Commands coordinate ATOM components:

```ruby
class ProcessCommand
  def execute
    # Use Molecules for focused operations
    data = Ace::Gem::Molecules::FileLoader.load(@file)

    # Use Organisms for business logic
    result = Ace::Gem::Organisms::Processor.new(data, @options).process

    # Return result
    result.success? ? 0 : 1
  end
end
```

## Examples from Production

### ace-lint (Simple CLI)
```
lib/ace/lint/
├── commands/
│   └── lint_command.rb     # Main command
├── cli.rb                  # Thor entry with lint, version
└── version.rb
```

### ace-docs (Multiple Commands)
```
lib/ace/docs/
├── commands/
│   ├── status_command.rb
│   ├── update_command.rb
│   ├── diff_command.rb
│   └── validate_command.rb
├── cli.rb                  # Thor entry
└── version.rb
```

### ace-taskflow (Complex CLI)
```
lib/ace/taskflow/
├── commands/
│   ├── task_command.rb
│   ├── tasks_command.rb
│   ├── release_command.rb
│   ├── idea_command.rb
│   └── [... 10+ commands]
├── cli.rb                  # Thor entry
└── version.rb
```

## Configuration Integration

Commands use ace-core config cascade:

```ruby
class ProcessCommand
  def initialize(file, options = {})
    @file = file
    @config = Ace::Gem.config          # Gem configuration
    @verbose = options[:verbose] || @config['verbose']
    @timeout = options[:timeout] || @config['timeout']
  end
end
```

## Error Handling

Consistent error pattern across all gems:

```ruby
def execute
  validate_input!
  perform_work
  0
rescue ValidationError => e
  warn "Validation failed: #{e.message}"
  1
rescue => e
  warn "Error: #{e.message}"
  warn e.backtrace.join("\n") if @options[:debug]
  1
end
```

## Related Decisions

- **ADR-011**: ATOM Architecture - commands coordinate ATOM components
- **ADR-017**: Flat Test Structure - test/commands/ for command tests
- **ADR-019**: Configuration Architecture - commands use config cascade

## References

- **Thor Documentation**: http://whatisthor.com/
- **ace-core**: Configuration cascade
- **ace-test-support**: Command testing helpers
- **Production gems**: ace-lint, ace-docs, ace-taskflow

---

This ADR establishes Thor with commands/ directory as the standard CLI pattern for all ACE gems, providing consistency, testability, and maintainability.
