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

## Config.wrap() - Quick Merge Pattern

For the common pattern of merging gem defaults with user overrides, use `Config.wrap()`:

```ruby
require "ace/config"

# Instead of this:
config = Ace::Config::Models::Config.new(defaults, source: "my-gem")
result = config.merge(user_overrides).to_h

# Use this:
result = Ace::Config::Models::Config.wrap(defaults, user_overrides, source: "my-gem")
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `base` | Hash, nil | required | Base configuration to start with |
| `overrides` | Hash | `{}` | Values to merge on top |
| `source:` | String | `"wrap"` | Source label for debugging |
| `merge_strategy:` | Symbol | `:replace` | Array merge strategy (`:replace`, `:concat`, `:union`) |

### Examples

```ruby
# Basic merge
defaults = { "timeout" => 30, "retries" => 3 }
user_config = { "timeout" => 60 }

result = Ace::Config::Models::Config.wrap(defaults, user_config)
# => { "timeout" => 60, "retries" => 3 }

# With merge strategy for arrays
defaults = { "plugins" => ["core"] }
user_config = { "plugins" => ["extra"] }

# Replace (default)
Ace::Config::Models::Config.wrap(defaults, user_config)
# => { "plugins" => ["extra"] }

# Union
Ace::Config::Models::Config.wrap(defaults, user_config, merge_strategy: :union)
# => { "plugins" => ["core", "extra"] }

# Handling nil base
Ace::Config::Models::Config.wrap(nil, { "key" => "value" })
# => { "key" => "value" }
```

### When to Use

Use `Config.wrap()` when you need a one-liner to merge configuration hashes. It's particularly useful in gem module methods that compute configuration:

```ruby
module MyGem
  def self.config
    @config ||= Ace::Config::Models::Config.wrap(
      load_gem_defaults,
      resolve_user_config,
      source: "my-gem"
    )
  end
end
```

## Specific File Patterns

Resolve configuration for specific files:

```ruby
config = Ace::Config.create
result = config.resolve_file(["database.yml", "database.yaml"])
```

## Namespace Resolution

The `resolve_namespace` method provides a convenient API for resolving configuration by namespace path, automatically generating `.yml` and `.yaml` patterns:

```ruby
resolver = Ace::Config.create

# Single namespace
# Resolves: docs/config.yml, docs/config.yaml
config = resolver.resolve_namespace("docs")

# Nested namespaces
# Resolves: git/worktree/config.yml, git/worktree/config.yaml
config = resolver.resolve_namespace("git", "worktree")

# Custom filename
# Resolves: lint/kramdown.yml, lint/kramdown.yaml
config = resolver.resolve_namespace("lint", filename: "kramdown")

# Root config with custom filename
# Resolves: settings.yml, settings.yaml
config = resolver.resolve_namespace(filename: "settings")
```

### When to Use

Use `resolve_namespace` when:
- Your configuration follows a namespace-based structure (e.g., `ace/docs/config.yml`)
- You want to reduce boilerplate for common config resolution patterns
- You need both `.yml` and `.yaml` extension support automatically

Use `resolve_file` when:
- You need full control over file patterns
- You're working with non-standard file names
- You need glob patterns (e.g., `presets/*.yml`)

### Limitations

**No glob support**: `resolve_namespace` does not support glob patterns. For pattern matching (e.g., `presets/*.yml`), use `resolve_file` instead.

**Security**: Namespace segments are validated for security. Path traversal (`..`) and absolute paths (`/`) are rejected with an `ArgumentError`. If you're processing untrusted input, this validation provides defense-in-depth, but always sanitize user input at your application boundary.

### Implementation Note

`resolve_namespace` is **not memoized** - it re-reads files on each call. For repeated access to the same configuration, consider caching the result:

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

## Test Mode for Performance

When running tests, filesystem-based configuration resolution can become a bottleneck. ace-config provides a **test mode** that skips all filesystem operations, providing approximately 30x faster configuration resolution.

### Enabling Test Mode

**Option 1: In test_helper.rb (recommended)**

```ruby
# test/test_helper.rb
require "ace/config"

# Enable test mode to skip filesystem searches
# This significantly speeds up tests that don't need real config files
Ace::Config.test_mode = true
```

**Option 2: Environment variable**

```bash
export ACE_CONFIG_TEST_MODE=true
```

**Option 3: Per-resolver override**

```ruby
config = Ace::Config.create(test_mode: true)
```

### Mock Configuration Data

Provide mock data instead of reading from disk:

```ruby
# Global mock for all resolvers
Ace::Config.default_mock = { "key" => "value", "nested" => { "setting" => true } }
Ace::Config.test_mode = true

config = Ace::Config.create
config.resolve.get("key")         # => "value"
config.resolve.get("nested", "setting")  # => true

# Per-resolver mock
config = Ace::Config.create(
  test_mode: true,
  mock_config: { "specific" => "data" }
)
```

### Testing Real Filesystem Access

Some tests need to verify real config file behavior. Use `with_real_config`:

```ruby
def test_config_cascade_ordering
  Ace::Config.with_real_config do
    # This block uses real filesystem resolution
    config = Ace::Config.create
    result = config.resolve
    assert_equal expected_merged_config, result.data
  end
  # Outside the block, test_mode is restored
end
```

### Thread Safety

Test mode state is thread-local, ensuring parallel test runners (e.g., minitest-parallel) don't interfere with each other:

```ruby
# Thread 1: test mode enabled
Ace::Config.test_mode = true

# Thread 2: test mode disabled (doesn't affect Thread 1)
Ace::Config.test_mode = false
```

### Migration Guide for Gem Maintainers

If your gem uses ace-config, enable test mode in your test helper to speed up your test suite:

**Step 1**: Add to your test helper

```ruby
# my-gem/test/test_helper.rb
require "ace/config"
Ace::Config.test_mode = true
```

**Step 2**: Provide mock config if your tests check config values

```ruby
Ace::Config.default_mock = { "my_gem" => { "setting" => "test_value" } }
```

**Step 3**: Reset config in setup (already recommended practice)

```ruby
class MyGemTestCase < Minitest::Test
  def setup
    MyGem.reset_config!  # Your gem's reset method
    Ace::Config.reset_config!  # Clear ace-config caches
  end
end
```

**Step 4**: Test real config access where needed

```ruby
def test_real_config_integration
  Ace::Config.with_real_config do
    # Tests that verify actual file reading
  end
end
```

### Performance Comparison

| Mode | Resolution Time | Use Case |
|------|-----------------|----------|
| Normal | ~0.3ms | Production, real config needed |
| Test Mode | ~0.01ms | Unit tests, mock data sufficient |

Test mode is **30x faster** because it bypasses all filesystem operations (directory traversal, file existence checks, YAML parsing).

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
                       .resolve_namespace("taskflow")
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
- Use `resolve_file` with specific patterns for faster resolution
- VirtualConfigResolver builds a map once; call `reload!` if files change

## Migration Guide

### From resolve_for to resolve_file/resolve_namespace

The `resolve_for` method has been deprecated in favor of clearer alternatives:

| Old API | New API | Use When |
|---------|---------|----------|
| `resolve_for(["docs/config.yml"])` | `resolve_namespace("docs")` | Single namespace with default filename |
| `resolve_for(["lint/kramdown.yml"])` | `resolve_namespace("lint", filename: "kramdown")` | Single namespace with custom filename |
| `resolve_for(["presets/*.yml"])` | `resolve_file(["presets/*.yml"])` | Glob patterns or complex patterns |

**Examples:**

```ruby
# BEFORE (deprecated)
config.resolve_for(["docs/config.yml", "docs/config.yaml"])

# AFTER (preferred)
config.resolve_namespace("docs")
```

```ruby
# BEFORE (deprecated)
config.resolve_for(["git/worktree/config.yml"])

# AFTER (preferred)
config.resolve_namespace("git", "worktree")
```

```ruby
# BEFORE (deprecated) - glob patterns
config.resolve_for(["presets/*.yml", "presets/*.yaml"])

# AFTER (same API, renamed for clarity)
config.resolve_file(["presets/*.yml", "presets/*.yaml"])
```

### When to Use Each Method

- **`resolve_namespace`**: Use for namespace-based configuration paths where you want both `.yml` and `.yaml` extensions automatically handled. Provides path security validation.

- **`resolve_file`**: Use for explicit file patterns, glob patterns, or when you need full control over which files are matched.

### Deprecation Timeline

The `resolve_for` method emits deprecation warnings and will be removed in a future major version. Update your code to use `resolve_namespace` or `resolve_file` as appropriate.
