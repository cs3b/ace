# ADR-022: Configuration Default and Override Pattern

## Status

Accepted
Date: 2025-12-13
Supersedes: ADR-019-configuration-architecture

## Context

ADR-019 established ace-support-core's configuration cascade for ACE gems but left ambiguity around:

1. **Where default configuration lives** - Some gems hardcode defaults in Ruby, others use `.ace.example/` files
2. **How defaults merge with user overrides** - Unclear priority and merge strategy
3. **Backward compatibility** - How to handle renamed config keys without breaking existing configs

Current problems in practice:
- ace-taskflow has defaults hardcoded in `ConfigLoader::DEFAULT_CONFIG` hash
- Defaults in code become stale and diverge from `.ace.example/` examples
- Users can't see complete default configuration without reading source code
- Config key renames (like `done` → `completed`) require code changes for backward compatibility

## Decision

All ace-* gems **must** follow a three-tier configuration pattern:

### 1. Default Configuration (in gem)

Location: `ace-gem/.ace.example/gem-name/config.yml`

This file contains:
- Complete configuration with all available options
- Sensible defaults for all values
- Comments explaining each option
- Is the single source of truth for defaults

```yaml
# ace-taskflow/.ace.example/taskflow/config.yml
taskflow:
  root: ".ace-taskflow"
  directories:
    completed: "_archive"    # Use semantic names
    backlog: "_backlog"
```

### 2. User Configuration (project or home)

Location: `.ace/gem-name/config.yml` (project) or `~/.ace/gem-name/config.yml` (home)

- Partial configuration - only overrides what differs from defaults
- Project config overrides home config
- Nearest wins (current dir → parent → home)

### 3. Loading Pattern

```ruby
module Ace
  module GemName
    class Configuration
      # Load default config from gem's .ace.example directory
      def self.default_config
        @default_config ||= load_gem_defaults
      end

      def self.load_gem_defaults
        gem_root = File.expand_path("../../..", __dir__)
        default_file = File.join(gem_root, ".ace.example", "gem-name", "config.yml")

        # .ace.example/ MUST be included in gem - missing file is a packaging error
        unless File.exist?(default_file)
          raise "Default config not found: #{default_file}. " \
                "This is a gem packaging error - .ace.example/ must be included in the gem."
        end

        YAML.load_file(default_file)&.dig("gem_name") || {}
      end

      # Full config = defaults + user overrides
      def self.config
        @config ||= deep_merge(default_config, user_config)
      end

      def self.user_config
        Ace::Core.config.get('ace', 'gem-name') || {}
      end
    end
  end
end
```

### 4. Backward Compatibility for Renamed Keys

When renaming config keys, support both old and new keys with deprecation:

```ruby
# Get directory name with backward compatibility
def done_dir
  # New key first, then old key, then default
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||
    "_archive"
end
```

Optionally log deprecation warnings:

```ruby
def done_dir
  if config.dig("directories", "done") && !config.dig("directories", "completed")
    warn "DEPRECATION: 'directories.done' is deprecated, use 'directories.completed'"
  end
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||
    "_archive"
end
```

### 5. Configuration Priority (highest to lowest)

1. CLI options (runtime)
2. Environment variables (where applicable)
3. Project config: `.ace/gem-name/config.yml` (nearest wins)
4. User config: `~/.ace/gem-name/config.yml`
5. Gem defaults: `ace-gem/.ace.example/gem-name/config.yml`

### Requirements Summary

**DO:**
- ✅ Put complete defaults in `.ace.example/gem-name/config.yml`
- ✅ Load defaults from `.ace.example/` at runtime (not hardcoded)
- ✅ Merge user config over defaults (deep merge)
- ✅ Support old config keys with deprecation path
- ✅ Document config options with comments in `.ace.example/`
- ✅ Provide `reset_config!` for testing
- ✅ Use semantic key names (`completed` not `done` for directories)
- ✅ Include `.ace.example/` in gemspec (MUST be packaged with gem)
- ✅ Raise error if `.ace.example/` config missing (packaging error, not fallback)

**DON'T:**
- ❌ Hardcode default values in Ruby (use `.ace.example/` instead)
- ❌ Break backward compatibility without deprecation path
- ❌ Require users to copy entire config file to override one value
- ❌ Use config keys that conflict with status values (e.g., `done` directory vs `done` status)
- ❌ Silently fallback if `.ace.example/` missing (this hides packaging errors)

## Consequences

### Positive

- **Single source of truth**: Defaults in `.ace.example/` are authoritative
- **Discoverability**: Users see all options by looking at `.ace.example/`
- **Minimal user config**: Only override what differs from defaults
- **Backward compatible**: Renamed keys still work with deprecation warnings
- **Testable**: `reset_config!` clears cached config for test isolation
- **No code changes for defaults**: Update `.ace.example/` to change defaults

### Negative

- **File I/O at startup**: Loading `.ace.example/` file adds minor startup cost
- **Migration effort**: Existing gems need refactoring to use this pattern
- **Gem packaging**: `.ace.example/` must be included in gem distribution (raises error if missing)

### Neutral

- **YAML-only**: Configuration must be YAML format
- **Convention over configuration**: Standard locations reduce flexibility

## Migration from ADR-019

Gems currently following ADR-019 should:

1. Move hardcoded defaults to `.ace.example/gem-name/config.yml`
2. Update config loading to read from `.ace.example/` first
3. Add backward compatibility for any renamed keys
4. Add deprecation warnings for old key names
5. Update documentation to reference `.ace.example/` as authoritative source

## Examples from Production

### ace-taskflow (Target State)

Default config:
```yaml
# ace-taskflow/.ace.example/taskflow/config.yml
taskflow:
  root: ".ace-taskflow"
  task_dir: "t"
  directories:
    completed: "_archive"     # Renamed from 'done' for clarity
    backlog: "_backlog"
    deferred: "_deferred"
    parked: "_parked"
  terminal_statuses:
    - done
    - cancelled
    - suspended
    - superseded
```

Loading:
```ruby
def done_dir
  config.dig("directories", "completed") ||
    config.dig("directories", "done") ||  # backward compat
    "_archive"
end
```

### ace-lint (Multi-Tool)

```yaml
# ace-lint/.ace.example/lint/config.yml
lint:
  enabled_linters:
    - markdown
    - yaml
  fail_fast: false
```

Tool-specific (flat):
```yaml
# ace-lint/.ace.example/lint/kramdown.yml
input: GFM
line_width: 120
```

## Related Decisions

- **ADR-019**: Configuration Architecture (superseded by this ADR)
- **ADR-015**: Mono-Repo Migration - ace-core provides config cascade
- **ADR-018**: Thor CLI Commands - commands use config with CLI overrides

## References

- **ace-support-core**: ConfigFinder and config cascade implementation
- **docs/ace-gems.g.md**: Configuration patterns guide

---

This ADR supersedes ADR-019 by making explicit that default configuration should live in `.ace.example/` files rather than being hardcoded in Ruby, and establishes the pattern for backward-compatible config key changes.
