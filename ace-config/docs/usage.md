# ace-config Usage Guide

This guide covers advanced usage patterns for ace-config beyond the basics in the README.

## Configuration Cascade

ace-config resolves configuration through a cascade from most specific to least specific:

```
1. $CWD/.ace/           # Current directory
2. $PARENT/.ace/        # Each parent directory up to project root
3. $PROJECT_ROOT/.ace/  # Project-level config
4. $HOME/.ace/          # User preferences
5. $GEM_PATH/.ace-defaults/  # Gem defaults (lowest priority)
```

### Example Cascade

```
/home/user/project/
├── .git/               # Project root marker
├── .ace/
│   └── settings.yml    # Project defaults
└── src/
    └── feature/
        └── .ace/
            └── settings.yml  # Feature-specific overrides
```

When running from `/home/user/project/src/feature/`, the cascade merges:
1. `src/feature/.ace/settings.yml` (highest priority)
2. `.ace/settings.yml` (project level)
3. `~/.ace/settings.yml` (user preferences)

## Deep Merging

Configurations are deep-merged, with nearer values overriding farther ones:

```yaml
# Project .ace/settings.yml
database:
  host: localhost
  port: 5432
  pool: 5

# Feature .ace/settings.yml
database:
  pool: 10  # Override only this key
```

Result:
```yaml
database:
  host: localhost  # From project
  port: 5432       # From project
  pool: 10         # From feature
```

## Array Merge Strategies

Control how arrays are merged with the `merge_strategy` option:

### :replace (default)
Newer arrays completely replace older ones:

```ruby
config = Ace::Config.create(merge_strategy: :replace)
```

```yaml
# Base
features: [a, b]
# Override
features: [c, d]
# Result
features: [c, d]
```

### :concat
Append newer arrays to older ones:

```ruby
config = Ace::Config.create(merge_strategy: :concat)
```

```yaml
# Base
features: [a, b]
# Override
features: [c, d]
# Result
features: [a, b, c, d]
```

### :union
Merge arrays keeping unique values:

```ruby
config = Ace::Config.create(merge_strategy: :union)
```

```yaml
# Base
features: [a, b, c]
# Override
features: [b, c, d]
# Result
features: [a, b, c, d]
```

## Custom Folder Names

Use custom config and defaults folder names:

```ruby
# Use .my-app for config, .my-app-defaults for gem defaults
config = Ace::Config.create(
  config_dir: ".my-app",
  defaults_dir: ".my-app-defaults"
)
```

## Gem Defaults

Package default configuration with your gem:

```ruby
# In your gem's entry point
module MyGem
  def self.config
    @config ||= Ace::Config.create(
      config_dir: ".my-gem",
      defaults_dir: ".ace-defaults",
      gem_path: File.expand_path("..", __dir__)
    )
  end
end
```

Structure:
```
my-gem/
├── .ace-defaults/
│   └── config.yml    # Default configuration
└── lib/
    └── my_gem.rb
```

## Specific File Patterns

Resolve configuration for specific files:

```ruby
config = Ace::Config.create
result = config.resolve_for(["database.yml", "database.yaml"])
```

## Virtual Config Resolver

The VirtualConfigResolver provides a filesystem-like view of config files across the cascade:

```ruby
resolver = Ace::Config.virtual_resolver

# Find preset files
resolver.glob("presets/*.yml").each do |relative_path, absolute_path|
  puts "Found: #{relative_path} at #{absolute_path}"
end

# Check if file exists anywhere in cascade
if resolver.exists?("templates/default.md")
  path = resolver.resolve_path("templates/default.md")
end
```

### Nearer Wins

The virtual resolver returns the nearest version when files exist at multiple levels:

```
/project/.ace/presets/default.yml   # ← This is returned
/project/.ace/presets/default.yml
~/.ace/presets/default.yml
```

## Project Root Detection

ace-config automatically detects project roots using markers:

```ruby
# Default markers: .git, Gemfile, package.json, Cargo.toml, etc.
root = Ace::Config.find_project_root

# Custom markers
root = Ace::Config.find_project_root(
  markers: [".my-project-marker", "setup.py"]
)
```

### Environment Variable Override

Set `PROJECT_ROOT_PATH` to override auto-detection:

```bash
export PROJECT_ROOT_PATH=/path/to/project
```

## Path Expansion

Expand paths with environment variables and special prefixes:

```ruby
expander = Ace::Config.path_expander(
  source_dir: "/project/docs",
  project_root: "/project"
)

expander.expand("$HOME/file.txt")      # /home/user/file.txt
expander.expand("@/lib/main.rb")       # /project/lib/main.rb (@ = project root)
expander.expand("./relative.md")       # /project/docs/relative.md
```

## Test Isolation

Reset configuration state between tests:

```ruby
def setup
  Ace::Config.reset_config!
end
```

This clears cached project root detection, ensuring tests don't affect each other.

## Integration with Other ACE Gems

ace-config is designed to be the foundation for other ACE gems:

```ruby
# In ace-taskflow
require "ace/config"

module Ace
  module Taskflow
    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Config.create(config_dir: ".ace")
                       .resolve_for(["taskflow/config.yml"])
                       .data

        Ace::Config::Atoms::DeepMerger.merge(defaults, user_config)
      end
    end
  end
end
```

## Configuration File Formats

ace-config supports YAML files with these patterns:
- `settings.yml` / `settings.yaml`
- `config.yml` / `config.yaml`
- Custom patterns via `file_patterns` option

```ruby
config = Ace::Config.create
finder = Ace::Config.finder(
  file_patterns: ["my-config.yml", "my-config.yaml"]
)
```

## Error Handling

ace-config provides specific error classes:

```ruby
begin
  config = Ace::Config.create
  value = config.get("missing", "key")
rescue Ace::Config::ConfigNotFoundError => e
  puts "Config file not found: #{e.message}"
rescue Ace::Config::YamlParseError => e
  puts "Invalid YAML: #{e.message}"
end
```

## Performance Considerations

- Configuration resolution is memoized; call `reset!` to refresh
- Project root detection is cached; call `Ace::Config.reset_config!` to clear
- Use `resolve_for` with specific patterns for faster resolution
- VirtualConfigResolver builds a map once; call `reload!` if files change
