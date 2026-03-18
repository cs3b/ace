# ace-support-nav

Unified navigation and resource discovery for the ACE ecosystem.

## Overview

ace-support-nav provides unified navigation and path resolution across the ACE ecosystem. It automatically discovers handbooks bundled within ace-* gems, resolves resource URIs to actual file paths, and supports a multi-level override cascade (project > user > gem).

## Features

- **Automatic Discovery**: Discovers handbooks bundled in ace-* gems without configuration
- **URI Resolution**: Resolves resource URIs (wfi://, tmpl://, guide://, sample://, task://)
- **Override Cascade**: Multi-level overrides with @ prefix for source-specific lookups
- **Smart Pattern Matching**:
  - Subdirectory/prefix patterns (e.g., `prompt://guidelines/`)
  - Wildcard patterns auto-list without `--list` flag
  - Intelligent detection of multi-result patterns
- **Fuzzy Matching**: Intelligent autocorrection and partial path matching
- **Performance**: Fast cached lookups after initial scan (< 100ms)
- **Standard CLI**: Explicit subcommands (`resolve`, `list`, `create`, `sources`)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-support-nav'
```

Or install directly:

```bash
gem install ace-support-nav
```

## Usage

### Basic Usage

```bash
# Cascade search (searches all sources in order)
ace-nav resolve wfi://setup          # Finds first 'setup' workflow
ace-nav resolve tmpl://minitest      # Finds first matching template
ace-nav resolve guide://configuration # Finds first matching guide

# Source-specific with @ prefix
ace-nav resolve wfi://@ace-git/setup     # Only from ace-git gem
ace-nav resolve tmpl://@project/minitest # Only from project overrides
ace-nav resolve wfi://@user/setup        # Only from user overrides
```

### Content Retrieval

```bash
# Get content directly
ace-nav resolve wfi://setup --content           # First matching content
ace-nav resolve wfi://@ace-git/setup --content  # From specific source
```

### Resource Creation

```bash
# Create from template
ace-nav create wfi://bundle                  # Creates in project .ace-handbook
ace-nav create tmpl://@ace-test/minitest     # Uses ace-test template
```

### Resource Discovery

ace-nav intelligently detects patterns that should return multiple results:

```bash
# Automatic list mode (no --list needed!)
ace-nav resolve prompt://            # All prompts (protocol-only)
ace-nav resolve prompt://guidelines/ # All files in guidelines/ directory
ace-nav resolve "prompt://format/*"  # All files matching pattern
ace-nav resolve "wfi://create*"      # All workflows starting with 'create'

# Subdirectory and prefix patterns
ace-nav resolve prompt://focus/         # Lists all focus modules
ace-nav resolve prompt://focus/quality/ # Lists quality-specific focus modules
ace-nav resolve wfi://review/           # Lists all review-related workflows

# Explicit list mode still works
ace-nav list 'wfi://*'               # All workflows
ace-nav list 'tmpl://@project/*'     # Project template overrides
ace-nav list 'wfi://*test*'          # Test-related workflows
```

### Task Navigation

The `task://` protocol delegates to `ace-task` commands, providing unified navigation across all ACE resources.

```bash
# Basic task navigation
ace-nav resolve task://083                   # Show task summary
ace-nav resolve task://083 --path            # Get task file path
ace-nav resolve task://083 --content         # Show full task content
ace-nav resolve task://083 --tree            # Show task dependencies

# All ace-taskflow reference formats supported
ace-nav resolve task://018                   # Task in current context
ace-nav resolve task://task.018              # Prefixed format
ace-nav resolve task://v.0.9.0+task.018      # Specific release
ace-nav resolve task://backlog+025           # Backlog tasks

# Shell integration
nvim $(ace-nav resolve task://083 --path)    # Open task in editor
```

## Configuration

Configuration is stored in `.ace/nav/` directory:

```yaml
# .ace/nav/config.yml
handbooks:
  sources:
    - gem: "ace-*"              # All ace-* gems
    - path: "/opt/handbooks"    # Custom path
      alias: "handbooks"        # Access as @handbooks

# Extension inference (DWIM - Do What I Mean)
extension_inference:
  enabled: true                 # Enable automatic extension detection
  fallback_order:               # Order of extension attempts
    - shorthand                 # 1. Protocol shorthand (wfi://workflow → wfi://workflow.wfi.md)
    - full                      # 2. Full extension (wfi://workflow.md)
    - generic                   # 3. Generic markdown (wfi://workflow.markdown.md)
    - bare                      # 4. No extension (wfi://workflow)

# Protocol-specific inferred extensions
protocols:
  wfi:
    inferred_extensions: [".wfi.md", ".md", ".markdown.md", ""]
  tmpl:
    inferred_extensions: [".tmpl.md", ".md", ".markdown.md", ""]
  guide:
    inferred_extensions: [".guide.md", ".md", ".markdown.md", ""]
  prompt:
    inferred_extensions: [".prompt.md", ".md", ".markdown.md", ""]
  sample:
    inferred_extensions: [".sample.md", ".md", ".markdown.md", ""]

# Built-in aliases:
# @project → ./.ace-handbook
# @user → ~/.ace-handbook
```

### Extension Inference

The extension inference feature enables DWIM (Do What I Mean) behavior by automatically trying common file extensions when a resource is not found. For example:

- `ace-nav resolve wfi://setup` will try: `setup.wfi.md`, `setup.md`, `setup.markdown.md`, `setup`
- `ace-nav resolve tmpl://custom` will try: `custom.tmpl.md`, `custom.md`, `custom.markdown.md`, `custom`

This reduces the need to type full extensions while maintaining compatibility with existing resources.

To disable extension inference:

```yaml
# .ace/nav/config.yml
extension_inference:
  enabled: false
```

To customize the fallback order:

```yaml
# .ace/nav/config.yml
extension_inference:
  fallback_order:
    - bare      # Try without extension first
    - full      # Then try .md
    - shorthand # Then try protocol-specific (.wfi.md)
```

## Override System

The cascade priority is:
1. **@project** - Project-specific overrides in `./.ace-handbook`
2. **@user** - User-level overrides in `~/.ace-handbook`
3. **@gem** - Bundled resources in ace-* gems

Use @ prefix to bypass cascade and target specific sources:
- `ace-nav resolve wfi://setup` - Cascade search (project > user > gems)
- `ace-nav resolve wfi://@ace-git/setup` - Only from ace-git gem
- `ace-nav resolve wfi://@project/setup` - Only from project overrides

## Ruby API

```ruby
require "ace/support/nav"

# Access configuration
Ace::Support::Nav.config

# Use CLI programmatically
Dry::CLI.new(Ace::Support::Nav::CLI).call(arguments: ["resolve", "wfi://setup"])

# Use navigation engine directly
engine = Ace::Support::Nav::Organisms::NavigationEngine.new
result = engine.resolve("wfi://setup")
```

## Development

After checking out the repo, run:

```bash
bundle install
ace-test ace-support-nav
```

## Contributing

Bug reports and pull requests are welcome at https://github.com/cs3b/ace.

## License

The gem is available as open source under the terms of the MIT License.
