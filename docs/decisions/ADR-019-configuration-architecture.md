# ADR-019: Configuration Architecture

## Status
Accepted
Date: October 14, 2025

## Context

As ACE grew to 15+ gems, configuration management became critical. Early gems used different approaches:
- Some hardcoded paths
- Some created custom config loaders
- Some used different file locations
- Inconsistent flat vs nested YAML structure

This led to:
- Duplication of config code
- Inconsistent user experience
- Configuration bugs across gems
- Difficulty maintaining configs

ace-core provided a solution with its config cascade system, but not all gems adopted it correctly.

## Decision

All ace-* gems **must** use ace-core's configuration cascade with standardized patterns.

### Dependency Requirement

```ruby
# ace-gem.gemspec
spec.add_dependency "ace-core", "~> 0.9"
```

### Configuration Locations

**Project config** (nearest wins):
```
.ace/gem-name/config.yml
```

**User config** (fallback):
```
~/.ace/gem-name/config.yml
```

**Example config** (in gem):
```
ace-gem/.ace.example/gem-name/config.yml
```

### Loading Pattern

```ruby
# lib/ace/gem.rb
module Ace
  module Gem
    def self.config
      @config ||= begin
        Ace::Core.config.get('ace', 'gem') || default_config
      rescue => e
        warn "Warning: Could not load config: #{e.message}"
        default_config
      end
    end

    def self.default_config
      {
        'verbose' => false,
        'timeout' => 30
      }
    end

    def self.reset_config!
      @config = nil
    end
  end
end
```

### Structure Rules

**Single-Purpose Gem (Flat Config):**
```yaml
# .ace/gem/config.yml
verbose: false
timeout: 30
enabled: true
```

```ruby
# Loading
config = Ace::Core.config.get('ace', 'gem')
# Returns: { 'verbose' => false, 'timeout' => 30, 'enabled' => true }
```

**Multi-Tool Gem (Mixed Structure):**

General config (nested):
```yaml
# .ace/lint/config.yml
ace:
  lint:
    enabled_linters:
      - markdown
      - yaml
```

Tool-specific config (flat):
```yaml
# .ace/lint/kramdown.yml
input: GFM
line_width: 120
auto_ids: false
```

```ruby
# Loading general
config = Ace::Core.config.get('ace', 'lint')
# Returns: { 'enabled_linters' => ['markdown', 'yaml'] }

# Loading tool-specific
kramdown = Ace::Core.config.get('ace', 'lint', 'kramdown')
# Returns: { 'input' => 'GFM', 'line_width' => 120, ... }
```

### Rules Summary

**Use FLAT structure** (no `ace:` nesting) for:
- Single-purpose gem main config
- Tool-specific configs (kramdown, prettier, etc.)
- Direct tool options

**Use NESTED structure** (`ace: { gem: {...} }`) for:
- General gem settings when gem has multiple tools
- Configuration loaded via `Ace::Core.config.get('ace', 'gem_name')`

### Requirements

**DO:**
- ✅ Use `Ace::Core.config.get('ace', 'gem')` for loading
- ✅ Provide `default_config` method
- ✅ Handle loading errors gracefully
- ✅ Create `.ace.example/gem/` with example config
- ✅ Provide `reset_config!` for testing
- ✅ Document config in gem's README
- ✅ Use flat structure for main/tool configs

**DON'T:**
- ❌ Hardcode config file paths: `~/.ace/gem/config.yml`
- ❌ Create custom ConfigLoader classes
- ❌ Put config files in project root: `.gem.yml`
- ❌ Fail if config missing (use defaults)
- ❌ Skip example configs in `.ace.example/`

## Consequences

### Positive

- **Consistency**: All gems load config same way
- **User Experience**: Same config pattern everywhere
- **Cascade Support**: Project overrides user config
- **Error Handling**: Graceful fallback to defaults
- **Testability**: `reset_config!` enables clean tests
- **Discoverability**: `.ace.example/` shows available options

### Negative

- **ace-core Dependency**: All gems depend on ace-core
- **Learning Curve**: Must understand cascade system
- **Migration Effort**: Existing custom loaders need removal

### Neutral

- **Directory Structure**: `.ace/` becomes standard but not .git-ignored by default
- **YAML Only**: Configuration must be YAML format

## Examples from Production

### ace-lint (Multi-Tool)

General config:
```yaml
# .ace/lint/config.yml
ace:
  lint:
    enabled_linters: [markdown, yaml]
```

Tool config (flat):
```yaml
# .ace/lint/kramdown.yml
input: GFM
line_width: 120
```

Loading:
```ruby
def self.config
  Ace::Core.config.get('ace', 'lint') || {}
end

def self.kramdown_config
  Ace::Core.config.get('ace', 'lint', 'kramdown') || default_kramdown_config
end
```

### ace-docs (Single-Purpose)

Config (flat):
```yaml
# .ace/docs/config.yml
auto_update: true
check_frequency: weekly
```

Loading:
```ruby
def self.config
  Ace::Core.config.get('ace', 'docs') || {
    'auto_update' => true,
    'check_frequency' => 'weekly'
  }
end
```

### ace-search (Simple)

Config (flat):
```yaml
# .ace/search/config.yml
default_mode: content
case_sensitive: false
```

Loading:
```ruby
def self.config
  @config ||= Ace::Core.config.get('ace', 'search') || default_config
end
```

## CLI Integration

Commands use config with CLI overrides:

```ruby
class ProcessCommand
  def initialize(options = {})
    config = Ace::Gem.config

    # CLI options override config
    @verbose = options[:verbose] || config['verbose']
    @timeout = options[:timeout] || config['timeout']
  end
end
```

Priority: CLI options > project config > user config > defaults

## Testing Pattern

```ruby
# test/gem_test.rb
class GemTest < AceTestCase
  def setup
    Ace::Gem.reset_config!
  end

  def test_default_config
    config = Ace::Gem.config
    assert_equal false, config['verbose']
    assert_equal 30, config['timeout']
  end

  def test_config_with_stub
    stub_config = { 'verbose' => true }
    Ace::Core.config.stub :get, stub_config do
      config = Ace::Gem.config
      assert_equal true, config['verbose']
    end
  end
end
```

## Documentation Pattern

### README.md (Brief)

```markdown
## Configuration

Uses ace-core config cascade: `.ace/gem/config.yml`

**Defaults:**
- verbose: false
- timeout: 30

See [.ace.example/gem/config.yml](.ace.example/gem/config.yml) for all options.
```

### .ace.example/gem/config.yml (Complete)

```yaml
# Example configuration for ace-gem
# Copy to .ace/gem/config.yml (project) or ~/.ace/gem/config.yml (user)

verbose: false    # Enable verbose output
timeout: 30       # Processing timeout in seconds
enabled: true     # Enable/disable gem functionality
```

## Related Decisions

- **ADR-015**: Mono-Repo Migration - ace-core provides config
- **ADR-018**: Thor CLI Commands - commands use config
- **ace-core**: Provides ConfigFinder and config cascade

## References

- **ace-core**: Configuration cascade implementation
- **ace-lint**: Multi-tool config example
- **ace-docs**: Single-purpose config example
- **docs/ace-gems.g.md**: Configuration patterns guide

---

This ADR establishes ace-core config cascade as the mandatory configuration pattern for all ACE gems, providing consistency, flexibility, and maintainability.
