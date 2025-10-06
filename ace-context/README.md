# ace-context

Context loading and caching for the ACE (Agent Coding Environment) ecosystem. Provides smart project context extraction for AI agents and developers.

## Installation

```bash
gem install ace-context
```

Or add to your Gemfile:

```ruby
gem 'ace-context', '~> 0.11.0'
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

# Load via protocol (ace-nav integration)
ace-context wfi://create-task          # Load workflow
ace-context guide://testing            # Load guide
ace-context task://061                 # Load task context

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
  diffs:
    - origin/main...HEAD    # Git diff ranges
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
---

# Project Context

Additional markdown content for this preset...
```

### Content Sources

ace-context supports multiple content sources that can be combined:

**Files**: Glob patterns for file inclusion
```yaml
context:
  files:
    - README.md
    - "lib/**/*.rb"
    - docs/architecture.md
```

**Commands**: Execute shell commands and include output
```yaml
context:
  commands:
    - git status --short
    - git log -5 --oneline
    - date
```

**Diffs**: Include git diff output for code review
```yaml
context:
  diffs:
    - origin/main...HEAD      # Changes in current branch
    - HEAD~5..HEAD           # Last 5 commits
    - --cached               # Staged changes
```

**Presets**: Include other ace-context presets
```yaml
context:
  presets:
    - project
    - architecture
```

**Protocols**: Reference resources via ace-nav protocols
```yaml
context:
  files:
    - wfi://draft-task        # Workflow via wfi:// protocol
    - wfi://plan-task         # Another workflow
    - guide://testing         # Guide via guide:// protocol
```

Protocols work in:
- Input arguments: `ace-context wfi://create-task`
- `context.files` arrays in YAML frontmatter
- Automatic recursive resolution for nested protocol references

Supported protocols (via ace-nav):
- `wfi://` - Workflow instructions
- `guide://` - Development guides
- `task://` - Task context (future)
- Any custom protocol registered with ace-nav

All sources can be combined in a single configuration:
```yaml
context:
  presets: [project]
  files:
    - "lib/new-feature/**/*.rb"
    - wfi://draft-task           # Protocol reference
  diffs: ["origin/main...HEAD"]
  commands: ["git log -5 --oneline"]
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

# Load via protocol
context = Ace::Context.load_auto('wfi://create-task')
puts context.content

# Load from file
context = Ace::Context.load_file('README.md')

# Auto-detect input type (preset, file, protocol, or inline YAML)
context = Ace::Context.load_auto('project')          # Preset
context = Ace::Context.load_auto('wfi://workflow')   # Protocol
context = Ace::Context.load_auto('/path/to/file')    # File

# List presets
presets = Ace::Context.list_presets
presets.each { |p| puts p[:name] }
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