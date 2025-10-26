# Ace::Core

Foundational gem providing configuration cascade resolution and shared functionality for all ace-* gems. This gem implements a configuration cascade system (.ace directories) with deep merging, environment variable handling, and follows the ATOM architecture pattern.

## Features

- **Configuration Cascade**: Search and merge configs from `./.ace` → `~/.ace` → gem defaults
- **Deep Merging**: Intelligent merging of nested configuration with configurable array strategies
- **Environment Variables**: Load and manage .env files with proper precedence
- **ATOM Architecture**: Clean separation of concerns using Atoms, Molecules, Organisms pattern
- **Zero Dependencies**: Uses only Ruby standard library for maximum compatibility

## Installation

Add this gem to your application's Gemfile:

```ruby
gem 'ace-core'
```

Or install it directly:

```bash
$ gem install ace-core
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

### Custom Configuration Paths

```ruby
# Use custom search paths
config = Ace::Core.config(search_paths: ['./.custom', '~/.myapp'])

# Or create a resolver with custom settings
resolver = Ace::Core::Organisms::ConfigResolver.new(
  search_paths: ['./.ace', '~/.ace', '/etc/ace'],
  file_patterns: ['config.yml', '*/config.yml'],
  merge_strategy: :deep
)
config = resolver.resolve
```

### Creating Default Configuration

```ruby
# Create a default config file structure
Ace::Core.create_default_config('./.ace/core/config.yml')
```

### Path Resolution with PathExpander

PathExpander provides unified path resolution across ACE tools with automatic context inference:

```ruby
require 'ace/core/atoms/path_expander'

# For config files, workflows, templates, prompts
config_file = ".ace/nav/config.yml"
expander = Ace::Core::Atoms::PathExpander.for_file(config_file)

# Resolve multiple paths - context inferred once!
expander.resolve("./local/file.md")        # Source-relative (from config dir)
expander.resolve("docs/architecture.md")   # Project-relative (from project root)
expander.resolve("$HOME/.ace/custom.yml")  # Environment variable expansion
expander.resolve("/absolute/path.md")      # Absolute paths

# For CLI arguments
expander = Ace::Core::Atoms::PathExpander.for_cli
resolved = expander.resolve(ARGV[0])  # Uses current directory as context
```

**Protocol URI Support** (with ace-nav integration):

```ruby
# Register protocol resolver (e.g., ace-nav)
Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

# Now protocol URIs work automatically
expander.resolve("wfi://workflow-name")    # Resolves via ace-nav
expander.resolve("guide://testing")        # Workflow instructions
expander.resolve("tmpl://task-draft")      # Templates
```

**Path Resolution Rules**:
- Paths starting with `./` or `../`: Resolved relative to source document directory
- Paths without prefix: Resolved relative to project root
- Paths with `$VAR` or `${VAR}`: Environment variables expanded
- Protocol URIs (`protocol://`): Delegated to registered resolver
- Absolute paths: Used as-is

**Backward Compatible Class Methods**:

```ruby
# Legacy stateless methods still work
Ace::Core::Atoms::PathExpander.expand("~/docs")     # Expand tilde and env vars
Ace::Core::Atoms::PathExpander.join("a", "b", "c")  # Join path components
Ace::Core::Atoms::PathExpander.absolute?("/path")   # Check if absolute
Ace::Core::Atoms::PathExpander.protocol?("wfi://")  # Check if protocol URI
```

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

- **Atoms**: Pure functions with no side effects (`yaml_parser`, `env_parser`, `deep_merger`, `path_expander`)
- **Molecules**: Composed operations using Atoms (`yaml_loader`, `env_loader`, `config_finder`, `project_root_finder`)
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

Bug reports and pull requests are welcome on GitHub at https://github.com/ace-meta/ace-core.