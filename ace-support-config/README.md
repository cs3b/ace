---
doc-type: user
title: ace-config
purpose: Documentation for ace-support-config/README.md
ace-docs:
  last-updated: 2026-03-05
  last-checked: 2026-03-21
---

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

# Quick merge helper - merge defaults with overrides, return hash
Ace::Config::Models::Config.wrap(
  defaults,             # Base configuration (Hash or nil)
  overrides,            # Override values (Hash)
  source: "wrap",       # Source label for debugging
  merge_strategy: :replace  # Array merge strategy
)
```

### Resolver Methods

```ruby
resolver = Ace::Config.create

resolver.resolve                     # Full cascade resolution (memoized)
resolver.resolve_file(["file.yml"])  # Specific file patterns (not memoized)
resolver.resolve_namespace("docs")   # Namespace resolution: docs/config.yml (not memoized)
resolver.get("key", "nested")        # Direct value access
```

### Namespace Resolution

`resolve_namespace` provides a convenience API for resolving configuration by namespace path:

```ruby
resolver = Ace::Config.create

# Single namespace - resolves docs/config.yml and docs/config.yaml
config = resolver.resolve_namespace("docs")

# Nested namespaces - resolves git/worktree/config.yml
config = resolver.resolve_namespace("git", "worktree")

# Custom filename - resolves lint/kramdown.yml
config = resolver.resolve_namespace("lint", filename: "kramdown")

# Root config with custom filename - resolves settings.yml
config = resolver.resolve_namespace(filename: "settings")
```

This is equivalent to calling `resolve_file` with the appropriate patterns, but reduces boilerplate when working with namespace-based configurations.

**Note**: `resolve_namespace` does not support glob patterns. Use `resolve_file` for pattern matching (e.g., `presets/*.yml`). See [docs/usage.md](docs/usage.md) for security considerations.

## Architecture

ace-config follows the ATOM pattern:

- **Atoms** - Pure functions (DeepMerger, YamlParser, PathExpander)
- **Molecules** - Focused operations (ConfigFinder, ProjectConfigScanner, ProjectRootFinder, YamlLoader)
- **Organisms** - Business logic (ConfigResolver, VirtualConfigResolver)
- **Models** - Data structures (Config, CascadePath)

## ConfigFinder vs ProjectConfigScanner

Two molecules handle config discovery with complementary traversal directions:

| | `ConfigFinder` | `ProjectConfigScanner` |
|---|---|---|
| **Direction** | Upward (CWD → root) | Downward (root → packages) |
| **Use case** | Resolve config for current context | Discover all configs across monorepo |
| **Returns** | Ordered list of config file paths | Map of `location => files` |
| **Typical caller** | `ConfigResolver` (cascade resolution) | Tooling that needs cross-package awareness |

Use `ConfigFinder` when you need the effective config for a single invocation context. Use `ProjectConfigScanner` when you need to enumerate config across all packages (e.g., linting, reporting, migration tools).

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
