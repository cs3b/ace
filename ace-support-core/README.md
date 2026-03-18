# Ace::Support::Core

Foundational infrastructure gem providing configuration cascade resolution and shared functionality for all ace-* gems. This gem implements a configuration cascade system (.ace directories) with deep merging, environment variable handling, and follows the ATOM architecture pattern.

Part of the ace-support-* pattern for library-only infrastructure gems (no CLI tools).

## Features

- **Configuration Cascade**: Powered by ace-config gem with `./.ace` → `~/.ace` → gem defaults resolution
- **Deep Merging**: Intelligent merging of nested configuration with configurable merge strategies
- **Environment Variables**: Load and manage .env files with proper precedence
- **Filesystem Utilities**: Path resolution and project root finding via ace-support-fs
- **ATOM Architecture**: Clean separation of concerns using Atoms, Molecules, Organisms pattern

**Note**: During migration, gem defaults are loaded from `.ace.example/` (legacy) or `.ace-defaults/` (new standard). The fallback to `.ace.example` will be removed after all gems complete migration.

## Dependencies

- **ace-config** (~> 0.2): Generic configuration cascade management
- **ace-support-fs** (~> 0.1): Filesystem utilities (PathExpander, ProjectRootFinder, DirectoryTraverser)

## Installation

Add this gem to your application's Gemfile:

```ruby
gem 'ace-support-core'
```

Or install it directly:

```bash
$ gem install ace-support-core
```

## Usage

### Basic Configuration Loading

```ruby
require 'ace/core'

# Load configuration with cascade resolution
config = Ace::Core.config
# Searches: ./.ace/config.yml → ~/.ace/config.yml → gem defaults

# Get specific values
value = Ace::Core.get('ace', 'settings', 'verbose_logging')

# Or use the config object
config = Ace::Core.config
project_name = config.get('ace', 'project', 'name')
```

### Environment Variables

```ruby
# Load .env files automatically based on config
Ace::Core.load_environment

# Or use the environment manager directly
env = Ace::Core.environment
env.load  # Loads .env.local, .env based on config
env.set('MY_VAR', 'value')
env.get('MY_VAR', 'default')
```

### Custom Configuration

```ruby
# Create a resolver with custom directories
resolver = Ace::Config.create(
  config_dir: ".myapp",           # Custom config directory (default: .ace)
  defaults_dir: ".myapp-defaults", # Custom defaults directory
  gem_path: __dir__               # Gem root for bundled defaults (optional)
)
config = resolver.resolve

# Or use the ConfigResolver directly for more control
resolver = Ace::Core::Organisms::ConfigResolver.new(
  config_dir: ".ace",
  defaults_dir: ".ace-defaults",  # Or ".ace.example" for legacy gems
  gem_path: __dir__
)
config = resolver.resolve
```

### Creating Default Configuration

```ruby
# Create a default config file structure
Ace::Core.create_default_config('./.ace/core/config.yml')
```

### Path Resolution

Path expansion and project root finding are provided by the **ace-support-fs** gem:

```ruby
require 'ace/support/fs'

# PathExpander: unified path resolution with context inference
expander = Ace::Support::Fs::Atoms::PathExpander.for_file(".ace/nav/config.yml")
expander.resolve("./local/file.md")        # Source-relative
expander.resolve("docs/architecture.md")   # Project-relative

# ProjectRootFinder: locate project root by markers (.git, .ace, etc.)
root = Ace::Support::Fs::Molecules::ProjectRootFinder.find
root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current

# DirectoryTraverser: traverse config directories
traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new
config_dirs = traverser.find_config_directories
```

See **ace-support-fs** gem for complete documentation on path resolution, protocol URIs, and directory traversal.

## ConfigSummary

`ConfigSummary` provides configuration summary display for CLI commands. It shows effective configuration state to stderr, displaying only values that differ from defaults and filtering sensitive keys.

### Verbose-Only Behavior

**Important**: `ConfigSummary.display()` and `ConfigSummary.display_if_needed()` only show output when `--verbose` is passed. This keeps normal command output clean and readable.

```ruby
# Normal command execution (no config shown)
ace-gem command
# (output only)

# With --verbose flag (config shown)
ace-gem --verbose command
# Config: key=value key2=value2
# (output...)
```

### Usage in Commands

```ruby
require "ace/core"

# In your command execute method
def execute
  # Check for --help BEFORE displaying config
  return show_help if args.include?("--help") || args.include?("-h")

  # Config only shown when --verbose is used
  Ace::Core::Atoms::ConfigSummary.display_if_needed(
    command: "mycommand",
    config: MyGem.config,
    defaults: MyGem.default_config,
    options: @options,
    args: args
  )

  # ... rest of implementation
end
```

### Features

- **Verbose-only**: Output only shown when `options[:verbose]` is true
- **Help detection**: `display_if_needed` automatically skips output when help is requested
- **Sensitive key filtering**: Keys ending with `token`, `password`, `secret`, `credential`, `key`, `api_key` are filtered
- **Default diffing**: Only shows values that differ from defaults
- **Nested config**: Flattens nested hashes with dot notation (e.g., `llm.provider=google`)

## Configuration Structure

Configuration files are YAML with the following structure:

```yaml
ace:
  version: "0.9.0"

  # Configuration cascade settings
  config_cascade:
    enabled: true
    search_paths:
      - "./.ace"        # Project-local (highest priority)
      - "~/.ace"        # User home
    merge_strategy: deep  # deep, shallow, replace
    array_strategy: replace  # replace, concat, union

  # Environment variable handling
  environment:
    load_dotenv: true
    dotenv_files:
      - ".env.local"    # Local overrides
      - ".env"          # Project defaults

  # Your custom settings
  project:
    name: "my-project"
    custom_key: "custom_value"
```

## Architecture

This gem follows the ATOM (Atoms, Molecules, Organisms, Models) architecture:

- **Atoms**: Pure functions with no side effects (`yaml_parser`, `env_parser`, `deep_merger`)
- **Molecules**: Composed operations using Atoms (`yaml_loader`, `env_loader`, `config_finder`)
- **Organisms**: Business logic orchestration (`config_resolver`, `environment_manager`)
- **Models**: Data structures with no behavior (`config`, `cascade_path`)

## Development

After checking out the repo:

```bash
cd ace-core
bundle install
rake test  # Run the test suite
```

## Testing

The gem includes comprehensive tests for all ATOM layers:

```bash
rake test  # Run all tests
rake test TEST=test/organisms/config_resolver_test.rb  # Run specific test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cs3b/ace.