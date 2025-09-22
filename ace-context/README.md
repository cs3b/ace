# ace-context

Context loading and caching for the ACE (Agent Coding Environment) ecosystem. Provides smart project context extraction for AI agents and developers.

## Installation

```bash
gem install ace-context
```

Or add to your Gemfile:

```ruby
gem 'ace-context', '~> 0.9.0'
```

## Usage

### Command Line

```bash
# List available presets
ace-context --list

# Load default preset
ace-context

# Load specific preset
ace-context project

# Output modes
ace-context project --output stdio    # Output to terminal
ace-context project --output cache    # Save to cache (default for some presets)
ace-context project --output ./out.md # Save to specific file
```

### Configuration

Context presets are defined as markdown files with YAML frontmatter in `.ace/context/`:

```yaml
---
description: Project documentation
params:
  output: cache           # Default output mode: stdio, cache, or file path
  embed_itself: true      # Include file contents in output
  max_size: 10485760     # Max file size (10MB)
  timeout: 30            # Command timeout in seconds
context:
  files:
    - README.md
    - docs/**/*.md
  commands:
    - git status --short
    - date
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
---

# Project Context

Additional markdown content for this preset...
```

### Example Presets

The gem includes example presets in `.ace.example/context/`:

```bash
# Copy examples to your project
cp -r $(gem which ace-context | xargs dirname)/../.ace.example .ace
```

Example presets included:
- `default.md` - Basic README and docs
- `project.md` - Full project documentation with git status
- `minimal.md` - Just the README file
- `release.md` - Release and task tracking

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

### Output Modes

The `--output` flag controls where context is written:

- `stdio` - Output to terminal (default for most presets)
- `cache` - Save to `.cache/ace-context/[preset].md`
- `/path/to/file.md` - Save to specific file

Each preset can define its default output mode in the `params.output` field.

## Architecture

### Components

- **PresetManager** - Loads markdown presets from `.ace/context/`
- **ContextLoader** - Processes presets and loads context
- **FileAggregator** - Handles file patterns and glob expansion (via ace-core)
- **OutputFormatter** - Formats context for output (via ace-core)

### Preset Structure

Presets use YAML frontmatter with two main sections:

1. **params** - Tool configuration (output, embed_itself, max_size, timeout)
2. **context** - Content specification (files, commands, exclude)

## Development

This gem is part of the ace-meta project and uses:
- ace-core for configuration and file operations
- ace-test-support for testing utilities

## Testing

```bash
cd ace-context
bundle exec rake test
```

## License

MIT