---
doc-type: user
title: ace-support-config Usage Guide
purpose: Documentation for ace-support-config/docs/usage.md
ace-docs:
  last-updated: 2026-01-12
  last-checked: 2026-03-21
---

# ace-support-config Usage Guide

## Configuration Cascade

The `ace-support-config` gem provides a generic configuration cascade system that merges configuration from multiple sources with priority-based resolution.

## ace-config Command

`ace-support-config` ships the `ace-config` CLI for template discovery, initialization, and drift checks.

```bash
ace-config init [GEM] [--force] [--dry-run] [--global] [--verbose]
ace-config diff [GEM] [--global] [--local] [--file PATH] [--one-line]
ace-config list [--verbose]
ace-config version
ace-config help
```

### Cascade Priority (highest to lowest)

1. **Project level** - `<project_root>/.ace/`
2. **User level** - `~/.ace/`
3. **Gem defaults** - `.ace-defaults/` (lowest priority)

### Basic Usage

```ruby
require 'ace/support/config'

# Create a configuration resolver
config = Ace::Support::Config.create

# Resolve configuration from all sources
resolved = config.resolve

# Get nested values
value = resolved.get("key", "nested", "path")
```

## Deep Merging

The gem provides several array merge strategies when combining configurations:

### Strategies

- **`:replace`** (default) - Overlay array replaces base array
- **`:concat`** - Concatenate arrays
- **`:union`** - Set union (deduplicated)
- **`:coerce_union`** - Coerce scalars to arrays, union, filter blanks

```ruby
# Replace strategy (default)
config = Ace::Support::Config.create(merge_strategy: :replace)

# Concatenate arrays
config = Ace::Support::Config.create(merge_strategy: :concat)

# Set union
config = Ace::Support::Config.create(merge_strategy: :union)

# Coerce union - scalars become arrays, then union
config = Ace::Support::Config.create(merge_strategy: :coerce_union)
```

### Custom Merge

```ruby
# Use Config.wrap for one-liner merging
base_config = { "key" => "default" }
user_config = { "key" => "override" }

merged = Ace::Support::Config::Models::Config.wrap(base_config, user_config)
# => { "key" => "override" }
```

## Namespace-Based Configuration

Load configuration for a specific namespace (e.g., per-gem configuration):

```ruby
resolver = Ace::Support::Config.create

# Resolves: .ace/gem_name/config.yml or .ace/gem_name/config.yaml
gem_config = resolver.resolve_namespace("gem_name")

# With custom filename
# Resolves: .ace/docs/config.yml or .ace/docs/config.yaml
docs_config = resolver.resolve_namespace("docs", filename: "settings")
```

## Test Mode

For faster test execution, enable test mode to skip filesystem searches:

### Thread-Local Test Mode

```ruby
# Enable test mode
Ace::Support::Config.test_mode = true

# Create config (returns empty config immediately)
config = Ace::Support::Config.create

# Provide mock data
Ace::Support::Config.default_mock = { "key" => "value" }

# Create config with mock data
config = Ace::Support::Config.create
```

### Environment Variable Test Mode

```bash
# Enable test mode via environment variable
ACE_CONFIG_TEST_MODE=1 ruby my_script.rb
```

## Virtual Filesystem View

The `virtual_resolver` provides a "virtual filesystem" view where the nearest config file wins:

```ruby
resolver = Ace::Support::Config.virtual_resolver

# Find all config files matching a pattern
resolver.glob("presets/*.yml").each do |relative, absolute|
  puts "Found: #{relative} at #{absolute}"
end

# Check if a file exists anywhere in the cascade
if resolver.exists?("templates/default.md")
  path = resolver.resolve_path("templates/default.md")
  # Use the file...
end
```

## Custom Folder Names

Use custom configuration folder names instead of the default `.ace`:

```ruby
config = Ace::Support::Config.create(
  config_dir: ".my-app",      # instead of .ace
  defaults_dir: ".my-app-defaults"  # instead of .ace-defaults
)
```

## Gem Defaults

To provide default configuration from your gem:

```ruby
# In your gem's lib/your_gem.rb
require 'ace/support/config'

module YourGem
  def self.config
    @config ||= Ace::Support::Config.create(
      gem_path: __dir__,  # Path to your gem root
      defaults_dir: ".your-gem-defaults"
    )
  end
end
```

## Path Expansion

The gem integrates with `ace-support-fs` for path expansion:

```ruby
expander = Ace::Support::Config.path_expander(
  source_dir: File.expand_path("../config", __FILE__),
  project_root: Dir.pwd
)

# Expand paths relative to source directory
absolute_path = expander.expand("../data/file.yml")
```

## Reset Configuration State

Clear all cached configuration (useful for tests):

```ruby
Ace::Support::Config.reset_config!
```

This clears:
- Project root cache
- Thread-local test mode state
- Thread-local mock data
