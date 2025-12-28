# ace-config

Generic configuration cascade management for Ruby applications.

## Overview

ace-config provides a reusable configuration cascade system with customizable folder names. It supports:

- **Project-level configuration** - Config files in `.ace/` (or custom folder) directories
- **User-level configuration** - Config files in `~/.ace/` (or custom folder)
- **Gem defaults** - Default config bundled with gems in `.ace-defaults/` (or custom folder)
- **Deep merging** - Configurations are merged with configurable strategies
- **Priority resolution** - Nearer config files override farther ones

## Installation

Add to your Gemfile:

```ruby
gem "ace-config"
```

## Quick Start

```ruby
require "ace/config"

# Create resolver with defaults
config = Ace::Config.create
value = config.get("some", "key")

# Create with custom folder names
config = Ace::Config.create(
  config_dir: ".my-app",        # User config folder
  defaults_dir: ".my-defaults"  # Gem defaults folder
)

# With gem defaults
config = Ace::Config.create(
  gem_path: __dir__,
  defaults_dir: ".ace-defaults"
)

# Resolve specific file patterns
config = Ace::Config.create
result = config.resolve_for(["settings.yml", "config.yml"])
```

## Configuration Cascade

The cascade resolves configuration in this order (highest to lowest priority):

1. `$CWD/{config_dir}/` - Current directory config
2. Intermediate directories between CWD and PROJECT_ROOT
3. `$PROJECT_ROOT/{config_dir}/` - Project-level config
4. `$HOME/{config_dir}/` - User preferences
5. `$GEM_PATH/{defaults_dir}/` - Gem defaults (lowest priority)

## API Reference

### Factory Methods

```ruby
# Main entry point - create resolver
Ace::Config.create(
  config_dir: ".ace",           # Config folder name
  defaults_dir: ".ace-defaults", # Defaults folder name
  gem_path: nil,                # Gem root for defaults
  merge_strategy: :replace      # Array merge strategy (:replace, :concat, :union)
)

# Lower-level finder
Ace::Config.finder(config_dir: ".ace", defaults_dir: ".ace-defaults")

# Path expander
Ace::Config.path_expander(source_dir: dir, project_root: root)

# Find project root
Ace::Config.find_project_root(start_path: nil, markers: [...])
```

### Resolver Methods

```ruby
resolver = Ace::Config.create

resolver.resolve                     # Full cascade resolution
resolver.resolve_for(["file.yml"])   # Specific file patterns
resolver.get("key", "nested")        # Direct value access
```

## Architecture

ace-config follows the ATOM pattern:

- **Atoms** - Pure functions (DeepMerger, YamlParser, PathExpander)
- **Molecules** - Focused operations (ConfigFinder, ProjectRootFinder, YamlLoader)
- **Organisms** - Business logic (ConfigResolver, VirtualConfigResolver)
- **Models** - Data structures (Config, CascadePath)

## Directory Naming Conventions

| Directory | Purpose | When to use |
|-----------|---------|-------------|
| `.ace-defaults/` | Gem-bundled defaults | Inside gems at `gem_path` - lowest priority in cascade |
| `.ace/` | User/project config | In project directories - overrides defaults |

The naming distinction clarifies intent:
- **`-defaults`** suffix indicates read-only gem defaults (bundled with gem, not modified by users)
- **Plain config dir** (e.g., `.ace`) indicates user-editable configuration

This differs from the older `.ace.example/` pattern used in some ACE ecosystem gems, which serves a similar purpose but with different semantics (example configs to copy, vs. active defaults that are merged).

## License

MIT License
