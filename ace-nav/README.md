# ace-nav

Unified navigation and resource discovery for the ACE ecosystem.

## Overview

ace-nav provides unified navigation and path resolution across the ACE ecosystem. It automatically discovers handbooks bundled within ace-* gems, resolves resource URIs to actual file paths, and supports a multi-level override cascade (project > user > gem).

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
- **Simple CLI**: Single command with options, no complex subcommands

## Installation

Add to your Gemfile:

```ruby
gem 'ace-nav'
```

Or install directly:

```bash
gem install ace-nav
```

## Usage

### Basic Usage

```bash
# Cascade search (searches all sources in order)
ace-nav wfi://setup                   # Finds first 'setup' workflow
ace-nav tmpl://minitest              # Finds first matching template
ace-nav guide://configuration        # Finds first matching guide

# Source-specific with @ prefix
ace-nav wfi://@ace-git/setup         # Only from ace-git gem
ace-nav tmpl://@project/minitest     # Only from project overrides
ace-nav wfi://@user/setup            # Only from user overrides
```

### Content Retrieval

```bash
# Get content directly
ace-nav wfi://setup --content        # First matching content
ace-nav wfi://@ace-git/setup --content  # From specific source
```

### Resource Creation

```bash
# Create from template
ace-nav wfi://load-context --create  # Creates in project .ace/handbook
ace-nav tmpl://@ace-test/minitest --create  # Uses ace-test template
```

### Resource Discovery

ace-nav intelligently detects patterns that should return multiple results:

```bash
# Automatic list mode (no --list needed!)
ace-nav prompt://                    # All prompts (protocol-only)
ace-nav prompt://guidelines/         # All files in guidelines/ directory
ace-nav "prompt://format/*"          # All files matching pattern
ace-nav "wfi://create*"              # All workflows starting with 'create'

# Subdirectory and prefix patterns
ace-nav prompt://focus/               # Lists all focus modules
ace-nav prompt://focus/quality/       # Lists quality-specific focus modules
ace-nav wfi://review/                 # Lists all review-related workflows

# Explicit list mode still works
ace-nav 'wfi://*' --list             # All workflows
ace-nav 'tmpl://@project/*' --list   # Project template overrides
ace-nav 'wfi://*test*' --list        # Test-related workflows
```

**New in v0.9.1:** Patterns ending with `/` or containing wildcards (`*`, `?`) automatically enable list mode!

### Task Navigation

```bash
# Find tasks
ace-nav task://018                   # Task by number
ace-nav 'task://*nav*' --list       # Tasks matching pattern
ace-nav task://018 --content        # Task content
```

## Configuration

Configuration is stored in `.ace/nav/` directory:

```yaml
# .ace/nav/settings.yml
handbooks:
  sources:
    - gem: "ace-*"              # All ace-* gems
    - path: "/opt/handbooks"    # Custom path
      alias: "handbooks"        # Access as @handbooks

# Built-in aliases:
# @project → ./.ace/handbook
# @user → ~/.ace/handbook
```

## Override System

The cascade priority is:
1. **@project** - Project-specific overrides in `./.ace/handbook`
2. **@user** - User-level overrides in `~/.ace/handbook`
3. **@gem** - Bundled resources in ace-* gems

Use @ prefix to bypass cascade and target specific sources:
- `wfi://setup` - Cascade search (project > user > gems)
- `wfi://@ace-git/setup` - Only from ace-git gem
- `wfi://@project/setup` - Only from project overrides

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome at https://github.com/ace-framework/ace-nav.

## License

The gem is available as open source under the terms of the MIT License.