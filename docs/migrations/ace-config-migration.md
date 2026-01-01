# Migrating to ace-config

This guide covers migration to ace-config from previous configuration patterns.

## Overview

ace-config provides a generic configuration cascade system extracted from ace-support-core. It offers:

- **Customizable folder names**: Use `.my-app/` instead of `.ace/`
- **Generic API**: No ACE-specific conventions required
- **External compatibility**: Projects outside ACE can use it independently
- **Simplified merging**: `Config.wrap()` for common patterns

## For ace-* Gem Developers

### Before (ace-support-core pattern)

```ruby
require "ace/core/atoms/deep_merger"

module Ace
  module MyGem
    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Core.config.get("ace", "my_gem") || {}
        Ace::Core::Atoms::DeepMerger.merge(defaults, user_config)
      end
    end

    def self.load_gem_defaults
      gem_root = ::Gem.loaded_specs["ace-my-gem"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "my_gem", "config.yml")
      YAML.safe_load_file(defaults_path) || {}
    end

    def self.reset_config!
      @config = nil
    end
  end
end
```

### After (ace-config pattern)

```ruby
require "ace/config"

module Ace
  module MyGem
    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Config.create
                        .resolve_namespace("my_gem")
                        .to_h
        Ace::Config::Models::Config.wrap(defaults, user_config, source: "my-gem")
      end
    end

    def self.load_gem_defaults
      gem_root = ::Gem.loaded_specs["ace-my-gem"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "my_gem", "config.yml")

      unless File.exist?(defaults_path)
        raise "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

    def self.reset_config!
      @config = nil
    end
  end
end
```

### Key Changes

1. **Import change**: `require "ace/config"` instead of `require "ace/core/atoms/deep_merger"`
2. **User config**: Use `Ace::Config.create.resolve_namespace("my_gem")` instead of `Ace::Core.config.get()`
3. **Merging**: Use `Ace::Config::Models::Config.wrap()` instead of `DeepMerger.merge()`
4. **Gem dependency**: Add `ace-config` to gemspec instead of `ace-support-core` (for config only)

### Gemspec Change

```ruby
# Before
spec.add_dependency "ace-support-core", "~> 0.10"

# After
spec.add_dependency "ace-config", "~> 0.4"
```

Note: If you still need other ace-support-core functionality, keep both dependencies.

## For External Projects

Projects outside the ACE ecosystem can use ace-config independently:

### Installation

```ruby
# Gemfile
gem "ace-config"
```

### Basic Usage

```ruby
require "ace/config"

# Create resolver with default folder names (.ace/)
config = Ace::Config.create
value = config.get("database", "host")

# Or with custom folder names
config = Ace::Config.create(
  config_dir: ".my-app",
  defaults_dir: ".my-app-defaults"
)
```

### With Your Gem

```ruby
module MyApp
  def self.config
    @config ||= begin
      resolver = Ace::Config.create(
        config_dir: ".my-app",
        defaults_dir: ".my-app-defaults",
        gem_path: File.expand_path("..", __dir__)
      )
      resolver.resolve
    end
  end
end
```

### Directory Structure

```
my-gem/
├── .my-app-defaults/           # Gem defaults (lowest priority)
│   └── config.yml
├── lib/
│   └── my_gem.rb
└── my_gem.gemspec

/project/
├── .my-app/                    # Project config (overrides defaults)
│   └── config.yml
└── src/
    └── feature/
        └── .my-app/            # Feature-specific (highest priority)
            └── config.yml

~/.my-app/                      # User preferences (middle priority)
└── config.yml
```

## API Migration Reference

### resolve_for → resolve_file / resolve_namespace

The `resolve_for` method is deprecated. Use the appropriate replacement:

| Old API | New API | Use When |
|---------|---------|----------|
| `resolve_for(["docs/config.yml"])` | `resolve_namespace("docs")` | Simple namespace patterns |
| `resolve_for(["lint/kramdown.yml"])` | `resolve_namespace("lint", filename: "kramdown")` | Custom filename |
| `resolve_for(["presets/*.yml"])` | `resolve_file(["presets/*.yml"])` | Glob patterns |

### DeepMerger

DeepMerger is available in ace-config:

```ruby
# Before
Ace::Core::Atoms::DeepMerger.merge(base, overlay)

# After
Ace::Config::Atoms::DeepMerger.merge(base, overlay)
```

### Config.wrap() - New Helper

For the common pattern of merging defaults with overrides:

```ruby
# Before
config = Ace::Core::Atoms::DeepMerger.merge(defaults, user_config)

# After (equivalent, more concise)
config = Ace::Config::Models::Config.wrap(defaults, user_config)
```

## Directory Naming

### `.ace.example/` → `.ace-defaults/`

Task 157.08 renamed `.ace.example/` to `.ace-defaults/` across all gems:

```
# Before
ace-taskflow/.ace.example/taskflow/config.yml

# After
ace-taskflow/.ace-defaults/taskflow/config.yml
```

The `-defaults` suffix clarifies intent:
- **`.ace-defaults/`**: Read-only defaults bundled with gem
- **`.ace/`**: User-editable configuration

## Error Classes

Error classes are now in the `Ace::Config` namespace:

```ruby
# Before
rescue Ace::Core::ConfigNotFoundError

# After
rescue Ace::Config::ConfigNotFoundError
```

Available errors:
- `Ace::Config::Error` - Base class
- `Ace::Config::ConfigNotFoundError` - Config file not found
- `Ace::Config::YamlParseError` - Invalid YAML
- `Ace::Config::PathError` - Path resolution failed
- `Ace::Config::MergeStrategyError` - Invalid merge strategy

## Test Isolation

Reset configuration state between tests:

```ruby
def setup
  Ace::Config.reset_config!  # Clears cached project root
  MyGem.reset_config!        # Clear gem's cached config
end
```

## Compatibility Notes

- ace-config requires Ruby 3.0+
- ace-config depends on ace-support-fs for path utilities
- YAML files support both `.yml` and `.yaml` extensions
- Array merge strategies: `:replace` (default), `:concat`, `:union`

## Further Reading

- [ace-config README](../../ace-config/README.md)
- [ace-config Usage Guide](../../ace-config/docs/usage.md)
- [ADR-022: Configuration Default and Override Pattern](../decisions/ADR-022-configuration-default-and-override-pattern.md)
