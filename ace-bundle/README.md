# ace-bundle

Context loading and caching for the ACE (Agentic Coding Environment) ecosystem. Provides smart project context extraction for AI agents and developers.

## Installation

```bash
gem install ace-bundle
```

Or add to your Gemfile:

```ruby
gem 'ace-bundle', '~> 0.29.1'
```

## Usage

### Command Line

```bash
# List available presets
ace-bundle --list

# Show help
ace-bundle

# Load specific preset
ace-bundle project

# Load configuration from file (positional argument - auto-detected)
ace-bundle /path/to/config.yml         # Auto-detects as file
ace-bundle ./custom-context.md         # Auto-detects as markdown file

# Load configuration from file (explicit -f flag)
ace-bundle -f config.yml               # Explicitly load YAML configuration
ace-bundle -f config.md                # Explicitly load markdown with frontmatter
ace-bundle -f config1.yml -f config2.md # Load multiple files

# Mix presets and files
ace-bundle -p base -f custom.yml       # Combine preset with file config
ace-bundle -p base -f config.yml -p extended # Mix in any order

# Inspect configuration without execution
ace-bundle -f config.yml --inspect-config # View merged configuration

# Embed source document in output (overrides frontmatter setting)
ace-bundle prompt.md --embed-source   # CLI flag overrides embed_document_source
ace-bundle prompt.md -e               # Short form

# Load via protocol (ace-nav integration)
ace-bundle wfi://task/draft           # Load workflow
ace-bundle guide://testing            # Load guide
ace-bundle task://061                 # Load task context

# Output modes
ace-bundle project --output stdio    # Output to terminal
ace-bundle project --output cache    # Save to cache (default for some presets)
ace-bundle project --output ./out.md # Save to specific file
```

### Input Auto-Detection

The positional argument to `ace-bundle` supports automatic input type detection:

- **File paths**: If the input exists as a file, it's loaded as configuration
- **Preset names**: Simple names like 'project' or 'base' load from `.ace/bundle/presets/`
- **Protocol URLs**: `wfi://`, `guide://`, `task://` are resolved via ace-nav
- **Inline YAML**: Direct YAML configuration with `files:`, `commands:`, etc.

```bash
ace-bundle project                     # Detected as preset
ace-bundle /path/to/config.yml         # Detected as file
ace-bundle ./relative/path.md          # Detected as file
ace-bundle wfi://workflow-name         # Detected as protocol
```

### Configuration

Context presets are defined as markdown files with YAML frontmatter in `.ace/bundle/`:

```yaml
---
description: Project documentation
bundle:
  params:
    output: cache                  # Default output mode: stdio, cache, or file path
    max_size: 10485760            # Max file size (10MB)
    timeout: 30                   # Command timeout in seconds
  embed_document_source: true     # Include file contents in output (uses XML format)
  files:
    - README.md
    - docs/**/*.md
  commands:
    - git status --short
    - date
  diffs:
    - origin/main...HEAD          # Git diff ranges
  exclude:
    - "**/node_modules/**"
    - "**/vendor/**"
---

# Project Context

Additional markdown content for this preset...
```

When `embed_document_source: true`, files and commands are embedded using XML format:
```xml
<files>
<file path="README.md">
# Content here
</file>
</files>

<commands>
<command name="git status --short" success="true">
M lib/file.rb
</command>
</commands>
```

### File Configuration

In addition to presets, ace-bundle can load configuration directly from files using the `-f` option:

**YAML Configuration** (config.yml):
```yaml
description: Custom configuration
bundle:
  files:
    - README.md
    - "docs/**/*.md"
  commands:
    - echo "Custom command"
  params:
    output: cache
    format: markdown-xml
```

**Markdown with Frontmatter** (config.md):
```markdown
---
description: Configuration with preset composition
bundle:
  files:
    - custom-file.md
  presets:         # Reference and compose with existing presets
    - base
    - project
  params:
    output: stdio
---

# Additional Context

Any markdown content here becomes part of the context...
```

Files can:
- Define the same configuration structure as presets
- Reference and compose with existing presets via `presets:` key
- Override parameters with `params:`
- Be combined with presets: `ace-bundle -p base -f custom.yml`


### Content Sources

ace-bundle supports multiple content sources that can be combined:

**Files**: Glob patterns for file inclusion
```yaml
bundle:
  files:
    - README.md
    - "lib/**/*.rb"
    - docs/architecture.md
```

**Commands**: Execute shell commands and include output
```yaml
bundle:
  commands:
    - git status --short
    - git log -5 --oneline
    - date
```

**Diffs**: Include git diff output for code review. We recommend the `diff` key for its flexibility.
```yaml
bundle:
  # Recommended complex format
  diff:
    ranges:
      - "origin/main...HEAD"
    # 'since' is a convenient alternative to 'ranges'
    # since: "origin/main" # Expands to "origin/main...HEAD"
    paths: ["lib/**/*.rb"]   # Optional: filter by paths

  # A simpler format is also supported for basic use cases:
  # diffs:
  #   - "origin/main...HEAD"
```

**PRs**: Include GitHub Pull Request diffs (requires [GitHub CLI](https://cli.github.com/))
```yaml
bundle:
  # Single PR
  pr: 123

  # Multiple PRs with different formats
  pr:
    - 123                                        # Simple PR number
    - "owner/repo#456"                           # Qualified reference
    - "https://github.com/owner/repo/pull/789"   # GitHub URL
```

PR diffs are fetched using the `gh` CLI tool. Ensure you're authenticated (`gh auth login`).

**Presets**: Include other ace-bundle presets
```yaml
bundle:
  presets:
    - project
    - architecture
```

**Protocols**: Reference resources via ace-nav protocols
```yaml
bundle:
  files:
    - wfi://task/draft        # Workflow via wfi:// protocol
    - wfi://task/plan         # Another workflow
    - guide://testing         # Guide via guide:// protocol
```

Protocols work in:
- Input arguments: `ace-bundle wfi://task/draft`
- `context.files` arrays in YAML frontmatter
- Automatic recursive resolution for nested protocol references

Supported protocols (via ace-nav):
- `wfi://` - Workflow instructions
- `guide://` - Development guides
- `task://` - Task context (future)
- Any custom protocol registered with ace-nav

All sources can be combined in a single configuration:
```yaml
bundle:
  presets: [project]
  files:
    - "lib/new-feature/**/*.rb"
    - wfi://task/draft           # Protocol reference
  diff: {ranges: ["origin/main...HEAD"]}
  commands: ["git log -5 --oneline"]
```

### Example Presets

The gem includes example presets in `.ace-defaults/context/`:

```bash
# Copy examples to your project
cp -r $(gem which ace-bundle | xargs dirname)/../.ace-defaults .ace
```

Example presets included:
- `default.md` - Basic README and docs
- `project.md` - Full project documentation with git status
- `minimal.md` - Just the README file
- `release.md` - Release and task tracking

### Ruby API

```ruby
require 'ace/bundle'

# Load a preset
context = Ace::Bundle.load_preset('project')
puts context.content

# Load configuration from file
context = Ace::Bundle.load_file_as_preset('/path/to/config.yml')
puts context.content

# Load multiple inputs (presets and files)
context = Ace::Bundle.load_multiple_inputs(
  ['base', 'project'],           # Presets
  ['/path/to/custom.yml']         # Files
)
puts context.content

# Inspect configuration without loading content
context = Ace::Bundle.inspect_config(['base', '/path/to/config.yml'])
puts context.content  # Returns YAML of merged configuration

# Load via protocol
context = Ace::Bundle.load_auto('wfi://task/draft')
puts context.content

# Load from file
context = Ace::Bundle.load_file('README.md')

# Auto-detect input type (preset, file, protocol, or inline YAML)
context = Ace::Bundle.load_auto('project')          # Preset
context = Ace::Bundle.load_auto('wfi://workflow')   # Protocol
context = Ace::Bundle.load_auto('/path/to/file')    # File

# List presets
presets = Ace::Bundle.list_presets
presets.each { |p| puts p[:name] }
```

### Output Modes

The `--output` flag controls where context is written:

- `stdio` - Output to terminal (default for most presets)
- `cache` - Save to `.ace-local/bundle/[preset].md`
- `/path/to/file.md` - Save to specific file

Each preset can define its default output mode in the `params.output` field.

## Architecture

### Components

- **PresetManager** - Loads markdown presets from `.ace/bundle/`
- **ContextLoader** - Processes presets and loads context
- **FileAggregator** - Handles file patterns and glob expansion (via ace-support-core)
- **OutputFormatter** - Formats context for output (via ace-support-core)

### Preset Structure

Presets use YAML frontmatter with a unified `bundle:` section:

1. **bundle.params** - Tool configuration (output, max_size, timeout)
2. **bundle** - Content specification (embed_document_source, files, commands, diffs, exclude)

## Dependencies

ace-bundle relies on:
- **ace-support-core** - Configuration cascade and shared utilities
- **ace-git** - Git and GitHub operations (diffs, PR metadata, branch info)

### ace-git Integration (v0.20.0+)

As of v0.20.0, ace-bundle uses ace-git for all Git and GitHub operations. The internal `GitExtractor`, `PrIdentifierParser`, and `GhPrExecutor` modules have been removed in favor of centralized functionality in ace-git. This reduces code duplication and provides consistent error handling across ACE packages.

**Configuring Timeouts**

Timeouts for git operations can be configured via `.ace/git/config.yml`:

```yaml
# .ace/git/config.yml
git:
  timeout: 30           # Local git operations (diff, status, log)
  network_timeout: 60   # Network operations (gh CLI, PR fetches)
```

## Development

This gem is part of the ace-meta project and uses:
- ace-support-core for configuration and file operations
- ace-git for Git/GitHub operations
- ace-support-test-helpers for testing utilities

## Testing

```bash
cd ace-bundle
bundle exec rake test
```

## License

MIT
