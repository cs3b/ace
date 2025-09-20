# ace-context

Context loading for ACE projects.

## Purpose

This gem provides preset-based context loading functionality for ACE projects, with:
- Configuration cascade support via ace-core
- Multiple preset management
- File pattern matching with exclusions
- Multiple output formats (markdown, yaml)
- Caching support

## Installation

Add to your Gemfile:

```ruby
gem 'ace-context', '~> 0.9.0'
```

## Usage

### Command Line

```bash
# List available presets
context --list

# Load default preset
context

# Load specific preset
context --preset project

# Load from file
context --file docs/README.md

# Output in YAML format
context --preset project --format yaml
```

### Ruby API

```ruby
require 'ace/context'

# Load a preset
context = Ace::Context.load_preset('project')
puts context.content

# List presets
presets = Ace::Context.list_presets
presets.each { |p| puts p[:name] }

# Load from file
context = Ace::Context.load_file('README.md')
```

## Configuration

Configuration files are loaded from (in order of precedence):
1. `.ace/context.yml` (project)
2. `~/.ace/context.yml` (home)
3. Gem's `config/context.yml` (defaults)

### Example Configuration

```yaml
context:
  presets:
    my-preset:
      description: "My custom preset"
      include:
        - "src/**/*.rb"
        - "README.md"
      exclude:
        - "**/test/**"
      format: markdown
      cache: true
```

### Preset Options

- `description` - Human-readable description
- `include` - Array of glob patterns to include
- `exclude` - Array of glob patterns to exclude
- `format` - Output format (markdown, yaml)
- `cache` - Whether to cache the context
- `metadata` - Additional metadata to include

## Development

This gem is part of the ace-meta project and uses:
- ace-core for configuration cascade
- ace-test-support for testing utilities

## Testing

```bash
cd ace-context
bundle exec rake test
```