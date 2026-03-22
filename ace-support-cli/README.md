# ace-support-cli

Command metadata DSL, parser, registry, and runner primitives for ace-* CLIs.

## Overview

`ace-support-cli` provides the shared command framework used across ACE gems.

It includes:

- A command DSL for describing command metadata and arguments/options
- Parser primitives for turning argv into typed command parameters
- Registry-based command discovery and lookup
- Runner primitives for executing resolved commands with consistent help/error handling

## Installation

Add to your gemspec:

```ruby
spec.add_dependency "ace-support-cli", "~> 0.6"
```

## Basic Usage

```ruby
require "ace/support/cli"

class GreetCommand < Ace::Support::Cli::Command
  desc "Print a greeting"
  argument :name, type: :string, required: true
  option :upper, type: :boolean, default: false

  def call(name:, upper: false)
    message = "Hello, #{name}"
    puts(upper ? message.upcase : message)
    0
  end
end

registry = Ace::Support::Cli::Registry.new
registry.register("greet", GreetCommand)

exit_code = Ace::Support::Cli::Runner.new(registry).call(
  args: ["greet", "world", "--upper"]
)
```

## API Overview

- **`Ace::Support::Cli::Command`**: Base class and DSL for command definitions
- **`Ace::Support::Cli::Parser`**: Converts argv tokens into typed keyword args
- **`Ace::Support::Cli::Registry`**: Registers and resolves command paths
- **`Ace::Support::Cli::RegistryDsl`**: Adapter for module-level `register` semantics
- **`Ace::Support::Cli::Runner`**: Executes resolved commands and handles help/errors
- **`Ace::Support::Cli::StandardOptions`**: Shared CLI option definitions/conventions

## Part of ACE

`ace-support-cli` is part of [ACE](../README.md) (Agentic Coding Environment), a
CLI-first toolkit for agent-assisted development.

## License

MIT
