# ace-support-cli Migration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Defining a command with type-coerced options

**Goal**: Show that options declared with types arrive correctly typed — no manual conversion.

**Before (dry-cli)**:
```ruby
require "dry/cli"
require "ace/core/cli/dry_cli/base"

class TimeoutCommand < Dry::CLI::Command
  include Ace::Core::CLI::DryCli::Base

  desc "Run with timeout"

  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :rate,    type: :float,   default: 1.0, desc: "Request rate"
  option :tags,    type: :array,   desc: "Tags to apply"
  option :verbose, type: :boolean, default: false, desc: "Verbose output"

  argument :target, required: true, desc: "Target to run"

  def call(target:, timeout:, rate:, tags:, verbose:, **)
    # BUG: timeout is "30" (String), not 30 (Integer)
    # BUG: rate is "1.0" (String), not 1.0 (Float)
    # BUG: tags is only the last --tags value (overwrites)

    # Workaround 1: manual convert_types
    opts = convert_types(timeout: timeout, rate: rate)
    timeout = opts[:timeout]  # now Integer
    rate = opts[:rate]        # now Float

    # Workaround 2: manual .to_i
    timeout = timeout.to_i

    # Workaround 3: ArgvCoalescer for arrays (in exe file)
    # argv = Ace::Core::CLI::DryCli::ArgvCoalescer.call(ARGV, command_class)
  end
end
```

**After (ace-support-cli)**:
```ruby
require "ace/support/cli"
require "ace/core/cli/base"

class TimeoutCommand < Ace::Support::Cli::Command
  include Ace::Core::CLI::Base

  desc "Run with timeout"

  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :rate,    type: :float,   default: 1.0, desc: "Request rate"
  option :tags,    type: :array,   desc: "Tags to apply"
  option :verbose, type: :boolean, default: false, desc: "Verbose output"

  argument :target, required: true, desc: "Target to run"

  def call(target:, timeout:, rate:, tags:, verbose:, **)
    timeout.is_a?(Integer)  # => true (30, not "30")
    rate.is_a?(Float)       # => true (1.0, not "1.0")
    tags                    # => ["a", "b"] (accumulated from --tag a --tag b)
    verbose                 # => true/false (not "true"/"false")

    # No convert_types, no .to_i, no ArgvCoalescer needed
  end
end
```

### Scenario 2: Multi-command registry setup

**Goal**: Show that registry and runner setup follows the same pattern.

**Before (dry-cli)**:
```ruby
# lib/ace/my_tool/cli/registry.rb
require "dry/cli"

module Ace::MyTool::CLI
  Registry = Dry::CLI::Registry.new

  Registry.register "lint",    Commands::Lint
  Registry.register "version", Ace::Core::CLI::DryCli::VersionCommand.build(
    gem_name: "ace-my-tool", version: Ace::MyTool::VERSION
  )
  Registry.register "test" do |r|
    r.register "atoms",     Commands::TestAtoms
    r.register "molecules", Commands::TestMolecules
  end
end
```

**After (ace-support-cli)**:
```ruby
# lib/ace/my_tool/cli/registry.rb
require "ace/support/cli"

module Ace::MyTool::CLI
  Registry = Ace::Support::Cli::Registry.new

  Registry.register "lint",    Commands::Lint
  Registry.register "version", Ace::Support::Cli::VersionCommand.build(
    gem_name: "ace-my-tool", version: Ace::MyTool::VERSION
  )
  Registry.register "test" do |r|
    r.register "atoms",     Commands::TestAtoms
    r.register "molecules", Commands::TestMolecules
  end
end
```

### Scenario 3: Exe entry point

**Goal**: Show the executable entry point migration.

**Before (dry-cli)**:
```ruby
#!/usr/bin/env ruby
require "ace/my_tool/cli/registry"

# Workaround: preprocess ARGV for array options
argv = Ace::Core::CLI::DryCli::ArgvCoalescer.call(ARGV, command_class)

Dry::CLI.new(Ace::MyTool::CLI::Registry).call(arguments: argv)
```

**After (ace-support-cli)**:
```ruby
#!/usr/bin/env ruby
require "ace/my_tool/cli/registry"

# No ARGV preprocessing needed — arrays accumulate natively
Ace::Support::Cli::Runner.new(Ace::MyTool::CLI::Registry).call
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
